import ActivityKit
import Foundation

struct FocusTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let endDate: Date
        let remainingSeconds: Int
        let isPaused: Bool
    }
}
