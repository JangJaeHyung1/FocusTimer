import Foundation

enum FocusPeriodType: String, Codable, Hashable {
    case week
    case month
}

struct FocusPeriodSummary: Encodable, Hashable {
    let periodType: FocusPeriodType
    let periodKey: String
    let totalSeconds: Int

    enum CodingKeys: String, CodingKey {
        case periodType = "period_type"
        case periodKey = "period_key"
        case totalSeconds = "total_seconds"
    }
}

struct FocusRankingResult: Codable, Hashable {
    enum Status: String, Codable {
        case collecting
        case ranked
        case noData = "no_data"
    }

    let periodType: FocusPeriodType
    let periodKey: String
    let status: Status
    let topPercent: Int?
    let participantCount: Int

    enum CodingKeys: String, CodingKey {
        case periodType = "period_type"
        case periodKey = "period_key"
        case status
        case topPercent = "top_percent"
        case participantCount = "participant_count"
    }

    var localizedText: String? {
        switch status {
        case .collecting:
//            return "ranking_collecting".localized
            return nil
        case .ranked:
            guard let topPercent else { return nil }
            return "ranking_top_percent_format".localizedFormat(topPercent)
        case .noData:
            return nil
        }
    }
}

struct FocusRankingCacheLookup {
    let results: [FocusRankingResult]
    let requiresSync: Bool
}

enum FocusSummaryCalculator {
    static func currentWeek(
        records: [DataModel],
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> FocusPeriodSummary {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone
        let interval = calendar.dateInterval(of: .weekOfYear, for: now)
        let year = calendar.component(.yearForWeekOfYear, from: now)
        let week = calendar.component(.weekOfYear, from: now)

        return FocusPeriodSummary(
            periodType: .week,
            periodKey: String(format: "%04d-W%02d", year, week),
            totalSeconds: totalSeconds(in: interval, records: records)
        )
    }

    static func month(
        containing date: Date,
        records: [DataModel],
        timeZone: TimeZone = .current
    ) -> FocusPeriodSummary {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let interval = calendar.dateInterval(of: .month, for: date)
        let components = calendar.dateComponents([.year, .month], from: date)

        return FocusPeriodSummary(
            periodType: .month,
            periodKey: String(
                format: "%04d-%02d",
                components.year ?? 0,
                components.month ?? 0
            ),
            totalSeconds: totalSeconds(in: interval, records: records)
        )
    }

    static func currentPeriods(
        records: [DataModel],
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> [FocusPeriodSummary] {
        [
            currentWeek(records: records, now: now, timeZone: timeZone),
            month(containing: now, records: records, timeZone: timeZone)
        ]
    }

    static func isSameMonth(
        _ lhs: Date,
        _ rhs: Date,
        timeZone: TimeZone = .current
    ) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components: Set<Calendar.Component> = [.year, .month]
        return calendar.dateComponents(components, from: lhs)
            == calendar.dateComponents(components, from: rhs)
    }

    static func isWithinLatestTwelveMonths(
        _ date: Date,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard
            let currentMonth = calendar.dateInterval(of: .month, for: now)?.start,
            let selectedMonth = calendar.dateInterval(of: .month, for: date)?.start,
            let earliestMonth = calendar.date(byAdding: .month, value: -11, to: currentMonth)
        else { return false }

        return selectedMonth >= earliestMonth && selectedMonth <= currentMonth
    }

    private static func totalSeconds(
        in interval: DateInterval?,
        records: [DataModel]
    ) -> Int {
        guard let interval else { return 0 }
        return records.reduce(into: 0) { total, record in
            if interval.contains(record.date) {
                total += record.seconds
            }
        }
    }
}
