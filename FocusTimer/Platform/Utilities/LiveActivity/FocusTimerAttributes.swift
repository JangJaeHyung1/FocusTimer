import ActivityKit
import Foundation

struct FocusTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let endDate: Date
        let remainingSeconds: Int
        let totalSeconds: Int
        let isPaused: Bool
    }
}
