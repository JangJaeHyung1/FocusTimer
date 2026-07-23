import Foundation
import Security

struct SupabaseConfiguration {
    let projectReference: String
    let publishableKey: String

    var baseURL: URL {
        URL(string: "https://\(projectReference).supabase.co")!
    }

    static var bundled: SupabaseConfiguration? {
        guard
            let projectReference = Bundle.main.object(
                forInfoDictionaryKey: "SupabaseProjectRef"
            ) as? String,
            let publishableKey = Bundle.main.object(
                forInfoDictionaryKey: "SupabasePublishableKey"
            ) as? String
        else { return nil }

        let trimmedReference = projectReference.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = publishableKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmedReference.isEmpty,
            !trimmedKey.isEmpty,
            !trimmedReference.contains("$("),
            !trimmedKey.contains("$("),
            trimmedReference.range(of: "^[a-z0-9]{10,40}$", options: .regularExpression) != nil,
            trimmedKey.hasPrefix("sb_publishable_") || trimmedKey.split(separator: ".").count == 3
        else { return nil }

        return SupabaseConfiguration(
            projectReference: trimmedReference,
            publishableKey: trimmedKey
        )
    }
}

struct SupabaseAuthSession: Codable {
    let participantID: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

enum SupabaseClientError: LocalizedError {
    case notConfigured
    case invalidResponse
    case keychain(OSStatus)
    case http(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase project settings are missing."
        case .invalidResponse:
            return "Supabase returned an invalid response."
        case .keychain(let status):
            return "Keychain operation failed (\(status))."
        case .http(let statusCode, let message):
            return "Supabase request failed (\(statusCode)): \(message)"
        }
    }

    var isAuthenticationFailure: Bool {
        guard case .http(let statusCode, _) = self else { return false }
        return statusCode == 401
    }

    var isUnrecoverableRefreshFailure: Bool {
        guard case .http(let statusCode, _) = self else { return false }
        return (400...499).contains(statusCode)
    }
}

private enum FocusRankingKeychain {
    private static let service = "\(Bundle.main.bundleIdentifier ?? "FocusTimer").focus-ranking"

    private static func account(projectReference: String) -> String {
        "supabase.anonymous-session.\(projectReference)"
    }

    static func loadSession(projectReference: String) throws -> SupabaseAuthSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account(projectReference: projectReference),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw SupabaseClientError.keychain(status) }
        guard let data = result as? Data else { throw SupabaseClientError.invalidResponse }
        return try JSONDecoder().decode(SupabaseAuthSession.self, from: data)
    }

    static func save(
        _ session: SupabaseAuthSession,
        projectReference: String
    ) throws {
        let data = try JSONEncoder().encode(session)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account(projectReference: projectReference)
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw SupabaseClientError.keychain(updateStatus)
        }

        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(newItem as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw SupabaseClientError.keychain(addStatus) }
    }

    static func deleteSession(projectReference: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account(projectReference: projectReference)
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SupabaseClientError.keychain(status)
        }
    }
}

actor SupabaseAnonymousAuthService {
    private struct AuthUser: Decodable {
        let id: String
    }

    private struct AuthResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: TimeInterval
        let expiresAt: TimeInterval?
        let user: AuthUser?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case expiresAt = "expires_at"
            case user
        }
    }

    private let configuration: SupabaseConfiguration
    private var cachedSession: SupabaseAuthSession?

    init(configuration: SupabaseConfiguration) {
        self.configuration = configuration
    }

    func hasStoredSession() -> Bool {
        if cachedSession != nil { return true }
        return (try? FocusRankingKeychain.loadSession(
            projectReference: configuration.projectReference
        )) != nil
    }

    func validSession() async throws -> SupabaseAuthSession {
        let storedSession = try cachedSession ?? FocusRankingKeychain.loadSession(
            projectReference: configuration.projectReference
        )
        if let storedSession, storedSession.expiresAt > Date().addingTimeInterval(60) {
            cachedSession = storedSession
            return storedSession
        }

        if let storedSession {
            do {
                return try await refresh(session: storedSession)
            } catch let error as SupabaseClientError where error.isUnrecoverableRefreshFailure {
                try FocusRankingKeychain.deleteSession(
                    projectReference: configuration.projectReference
                )
                cachedSession = nil
            }
        }

        return try await createAnonymousSession()
    }

    func refreshSession() async throws -> SupabaseAuthSession {
        guard let session = try cachedSession ?? FocusRankingKeychain.loadSession(
            projectReference: configuration.projectReference
        ) else {
            return try await createAnonymousSession()
        }
        return try await refresh(session: session)
    }

    private func createAnonymousSession() async throws -> SupabaseAuthSession {
        let url = configuration.baseURL.appending(path: "auth/v1/signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        applyPublicHeaders(to: &request)

        let response: AuthResponse = try await perform(request)
        guard let participantID = response.user?.id else {
            throw SupabaseClientError.invalidResponse
        }
        return try store(response: response, participantID: participantID)
    }

    private func refresh(session: SupabaseAuthSession) async throws -> SupabaseAuthSession {
        var components = URLComponents(
            url: configuration.baseURL.appending(path: "auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]
        guard let url = components?.url else { throw SupabaseClientError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(
            withJSONObject: ["refresh_token": session.refreshToken]
        )
        applyPublicHeaders(to: &request)

        let response: AuthResponse = try await perform(request)
        return try store(response: response, participantID: response.user?.id ?? session.participantID)
    }

    private func store(
        response: AuthResponse,
        participantID: String
    ) throws -> SupabaseAuthSession {
        let expiry = response.expiresAt.map(Date.init(timeIntervalSince1970:))
            ?? Date().addingTimeInterval(response.expiresIn)
        let session = SupabaseAuthSession(
            participantID: participantID,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: expiry
        )
        try FocusRankingKeychain.save(
            session,
            projectReference: configuration.projectReference
        )
        cachedSession = session
        return session
    }

    private func applyPublicHeaders(to request: inout URLRequest) {
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseClientError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseClientError.http(
                statusCode: httpResponse.statusCode,
                message: Self.errorMessage(from: data)
            )
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private static func errorMessage(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return "Unknown error" }
        return (object["message"] as? String)
            ?? (object["error_description"] as? String)
            ?? (object["error"] as? String)
            ?? "Unknown error"
    }
}
