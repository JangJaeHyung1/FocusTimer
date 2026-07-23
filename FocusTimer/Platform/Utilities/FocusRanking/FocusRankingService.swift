import Foundation

actor FocusRankingService {
    static let shared = FocusRankingService()

    private struct CachedRanking: Codable {
        let totalSeconds: Int
        let fetchedAt: Date
        let result: FocusRankingResult
    }

    private struct RankingCache: Codable {
        let entries: [String: CachedRanking]
    }

    private struct SyncPayload: Encodable {
        let summaries: [FocusPeriodSummary]
        let timeZone: String

        enum CodingKeys: String, CodingKey {
            case summaries = "p_summaries"
            case timeZone = "p_time_zone"
        }
    }

    private struct SyncResponse: Decodable {
        let results: [FocusRankingResult]
    }

    private static let installationMarkerKeyPrefix = "focusRanking.installationInitialized"
    private static let cacheKeyPrefix = "focusRanking.resultCache.v1"
    private static let activePeriodCacheDuration: TimeInterval = 60 * 60
    private static let historicalMonthCacheDuration: TimeInterval = 24 * 60 * 60
    private static let maximumCachedPeriods = 32

    private let configuration: SupabaseConfiguration?
    private let authentication: SupabaseAnonymousAuthService?
    private var cachedRankings: [String: CachedRanking]
    private var inFlightRequests: [String: Task<[FocusRankingResult], Error>] = [:]
    private var installationPreparationTask: Task<Void, Error>?

    private init() {
        let configuration = SupabaseConfiguration.bundled
        self.configuration = configuration
        self.authentication = configuration.map(SupabaseAnonymousAuthService.init)
        self.cachedRankings = configuration.map {
            Self.loadCache(projectReference: $0.projectReference)
        } ?? [:]
    }

    func cachedLookup(
        for summaries: [FocusPeriodSummary],
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> FocusRankingCacheLookup {
        guard
            let configuration,
            UserDefaults.standard.bool(
                forKey: Self.installationMarkerKey(
                    projectReference: configuration.projectReference
                )
            )
        else {
            return FocusRankingCacheLookup(results: [], requiresSync: !summaries.isEmpty)
        }

        var results: [FocusRankingResult] = []
        var requiresSync = false

        for summary in summaries {
            let key = Self.cacheKey(
                periodType: summary.periodType,
                periodKey: summary.periodKey
            )
            guard
                let cachedRanking = cachedRankings[key],
                cachedRanking.totalSeconds == summary.totalSeconds
            else {
                requiresSync = true
                continue
            }

            results.append(cachedRanking.result)
            if !Self.isCacheFresh(
                cachedRanking,
                for: summary,
                now: now,
                timeZone: timeZone
            ) {
                requiresSync = true
            }
        }

        return FocusRankingCacheLookup(results: results, requiresSync: requiresSync)
    }

    func sync(_ summaries: [FocusPeriodSummary]) async throws -> [FocusRankingResult] {
        guard !summaries.isEmpty else { return [] }
        guard let configuration, let authentication else {
            throw SupabaseClientError.notConfigured
        }

        let now = Date()
        let timeZone = TimeZone.current
        let installationIsPrepared = UserDefaults.standard.bool(
            forKey: Self.installationMarkerKey(projectReference: configuration.projectReference)
        )
        var resultsByPeriod: [String: FocusRankingResult] = [:]
        var summariesToSync: [FocusPeriodSummary] = []

        for summary in summaries {
            let key = Self.cacheKey(
                periodType: summary.periodType,
                periodKey: summary.periodKey
            )
            if
                installationIsPrepared,
                let cachedRanking = cachedRankings[key],
                cachedRanking.totalSeconds == summary.totalSeconds,
                Self.isCacheFresh(
                    cachedRanking,
                    for: summary,
                    now: now,
                    timeZone: timeZone
                )
            {
                resultsByPeriod[key] = cachedRanking.result
            } else {
                summariesToSync.append(summary)
            }
        }

        guard !summariesToSync.isEmpty else {
            return Self.orderedResults(for: summaries, from: resultsByPeriod)
        }

        let requestKey = Self.requestKey(for: summariesToSync, timeZone: timeZone)
        let requestTask: Task<[FocusRankingResult], Error>
        let createdRequest: Bool

        if let existingRequest = inFlightRequests[requestKey] {
            requestTask = existingRequest
            createdRequest = false
        } else {
            requestTask = Task { [self] in
                try await fetchRankings(
                    summariesToSync,
                    configuration: configuration,
                    authentication: authentication,
                    timeZone: timeZone
                )
            }
            inFlightRequests[requestKey] = requestTask
            createdRequest = true
        }

        let fetchedResults: [FocusRankingResult]
        do {
            fetchedResults = try await requestTask.value
            if createdRequest {
                inFlightRequests[requestKey] = nil
            }
        } catch {
            if createdRequest {
                inFlightRequests[requestKey] = nil
            }

            let matchingCachedResults = summaries.compactMap { summary -> FocusRankingResult? in
                let key = Self.cacheKey(
                    periodType: summary.periodType,
                    periodKey: summary.periodKey
                )
                guard
                    let cachedRanking = cachedRankings[key],
                    cachedRanking.totalSeconds == summary.totalSeconds
                else { return nil }
                return cachedRanking.result
            }
            if matchingCachedResults.count == summaries.count {
                return matchingCachedResults
            }
            throw error
        }

        for result in fetchedResults {
            let key = Self.cacheKey(
                periodType: result.periodType,
                periodKey: result.periodKey
            )
            guard let summary = summariesToSync.first(where: {
                $0.periodType == result.periodType && $0.periodKey == result.periodKey
            }) else { continue }

            cachedRankings[key] = CachedRanking(
                totalSeconds: summary.totalSeconds,
                fetchedAt: now,
                result: result
            )
            resultsByPeriod[key] = result
        }

        pruneCacheIfNeeded()
        persistCache(projectReference: configuration.projectReference)

        return Self.orderedResults(for: summaries, from: resultsByPeriod)
    }

    private func fetchRankings(
        _ summaries: [FocusPeriodSummary],
        configuration: SupabaseConfiguration,
        authentication: SupabaseAnonymousAuthService,
        timeZone: TimeZone
    ) async throws -> [FocusRankingResult] {
        try await prepareInstallationIfNeeded(authentication: authentication)

        let payload = SyncPayload(
            summaries: summaries,
            timeZone: timeZone.identifier
        )
        let body = try JSONEncoder().encode(payload)
        let data = try await authenticatedRPC(
            name: "sync_focus_rankings",
            body: body,
            configuration: configuration,
            authentication: authentication
        )
        return try JSONDecoder().decode(SyncResponse.self, from: data).results
    }

    private static func installationMarkerKey(projectReference: String) -> String {
        "\(installationMarkerKeyPrefix).\(projectReference)"
    }

    private static func cacheStorageKey(projectReference: String) -> String {
        "\(cacheKeyPrefix).\(projectReference)"
    }

    private static func cacheKey(
        periodType: FocusPeriodType,
        periodKey: String
    ) -> String {
        "\(periodType.rawValue)|\(periodKey)"
    }

    private static func requestKey(
        for summaries: [FocusPeriodSummary],
        timeZone: TimeZone
    ) -> String {
        let periods = summaries.map {
            "\(cacheKey(periodType: $0.periodType, periodKey: $0.periodKey))=\($0.totalSeconds)"
        }
        .sorted()
        .joined(separator: ",")
        return "\(timeZone.identifier)|\(periods)"
    }

    private static func orderedResults(
        for summaries: [FocusPeriodSummary],
        from resultsByPeriod: [String: FocusRankingResult]
    ) -> [FocusRankingResult] {
        summaries.compactMap {
            resultsByPeriod[cacheKey(periodType: $0.periodType, periodKey: $0.periodKey)]
        }
    }

    private static func isCacheFresh(
        _ cachedRanking: CachedRanking,
        for summary: FocusPeriodSummary,
        now: Date,
        timeZone: TimeZone
    ) -> Bool {
        let cacheDuration: TimeInterval
        switch summary.periodType {
        case .week:
            cacheDuration = activePeriodCacheDuration
        case .month:
            cacheDuration = summary.periodKey == currentMonthKey(now: now, timeZone: timeZone)
                ? activePeriodCacheDuration
                : historicalMonthCacheDuration
        }

        let age = max(0, now.timeIntervalSince(cachedRanking.fetchedAt))
        return age < cacheDuration
    }

    private static func currentMonthKey(now: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month], from: now)
        return String(
            format: "%04d-%02d",
            components.year ?? 0,
            components.month ?? 0
        )
    }

    private static func loadCache(projectReference: String) -> [String: CachedRanking] {
        guard
            let data = UserDefaults.standard.data(
                forKey: cacheStorageKey(projectReference: projectReference)
            ),
            let cache = try? JSONDecoder().decode(RankingCache.self, from: data)
        else { return [:] }
        return cache.entries
    }

    private func persistCache(projectReference: String) {
        guard let data = try? JSONEncoder().encode(RankingCache(entries: cachedRankings)) else {
            return
        }
        UserDefaults.standard.set(
            data,
            forKey: Self.cacheStorageKey(projectReference: projectReference)
        )
    }

    private func pruneCacheIfNeeded() {
        guard cachedRankings.count > Self.maximumCachedPeriods else { return }
        let keysToRemove = cachedRankings
            .sorted { $0.value.fetchedAt > $1.value.fetchedAt }
            .dropFirst(Self.maximumCachedPeriods)
            .map { $0.key }
        keysToRemove.forEach { cachedRankings[$0] = nil }
    }

    private func prepareInstallationIfNeeded(
        authentication: SupabaseAnonymousAuthService
    ) async throws {
        guard let configuration else { throw SupabaseClientError.notConfigured }

        let defaults = UserDefaults.standard
        let installationMarkerKey = Self.installationMarkerKey(
            projectReference: configuration.projectReference
        )
        guard !defaults.bool(forKey: installationMarkerKey) else { return }

        if let installationPreparationTask {
            try await installationPreparationTask.value
            return
        }

        let preparationTask = Task { [self] in
            try await performInstallationPreparation(
                authentication: authentication,
                configuration: configuration,
                defaults: defaults,
                installationMarkerKey: installationMarkerKey
            )
        }
        installationPreparationTask = preparationTask

        do {
            try await preparationTask.value
            installationPreparationTask = nil
        } catch {
            installationPreparationTask = nil
            throw error
        }
    }

    private func performInstallationPreparation(
        authentication: SupabaseAnonymousAuthService,
        configuration: SupabaseConfiguration,
        defaults: UserDefaults,
        installationMarkerKey: String
    ) async throws {
        let hadStoredSession = await authentication.hasStoredSession()
        _ = try await authentication.validSession()

        if hadStoredSession {
            _ = try await authenticatedRPC(
                name: "reset_my_focus_totals",
                body: Data("{}".utf8),
                configuration: configuration,
                authentication: authentication
            )
        }

        defaults.set(true, forKey: installationMarkerKey)
    }

    private func authenticatedRPC(
        name: String,
        body: Data,
        configuration: SupabaseConfiguration,
        authentication: SupabaseAnonymousAuthService
    ) async throws -> Data {
        var session = try await authentication.validSession()
        do {
            return try await rpc(
                name: name,
                body: body,
                accessToken: session.accessToken,
                configuration: configuration
            )
        } catch let error as SupabaseClientError where error.isAuthenticationFailure {
            session = try await authentication.refreshSession()
            return try await rpc(
                name: name,
                body: body,
                accessToken: session.accessToken,
                configuration: configuration
            )
        }
    }

    private func rpc(
        name: String,
        body: Data,
        accessToken: String,
        configuration: SupabaseConfiguration
    ) async throws -> Data {
        let url = configuration.baseURL.appending(path: "rest/v1/rpc/\(name)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
        return data
    }

    private static func errorMessage(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return "Unknown error" }
        return (object["message"] as? String)
            ?? (object["details"] as? String)
            ?? (object["hint"] as? String)
            ?? "Unknown error"
    }
}
