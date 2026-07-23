import ActivityKit
import Foundation

final class FocusTimerLiveActivityManager {
    static let shared = FocusTimerLiveActivityManager()

    private init() { }

    func startOrResume(seconds: Int, totalSeconds: Int) {
        guard seconds > 0, ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = FocusTimerAttributes.ContentState(
            endDate: Date().addingTimeInterval(TimeInterval(seconds)),
            remainingSeconds: seconds,
            totalSeconds: max(totalSeconds, seconds, 1),
            isPaused: false
        )
        let content = ActivityContent(state: state, staleDate: state.endDate)

        if let activity = Activity<FocusTimerAttributes>.activities.first {
            Task {
                await activity.update(content)
            }
            return
        }

        do {
            _ = try Activity.request(
                attributes: FocusTimerAttributes(),
                content: content,
                pushType: nil
            )
        } catch {
            print("❌ Live Activity 시작 실패: \(error.localizedDescription)")
        }
    }

    func pause(seconds: Int, totalSeconds: Int) {
        guard let activity = Activity<FocusTimerAttributes>.activities.first else { return }

        let state = FocusTimerAttributes.ContentState(
            endDate: Date(),
            remainingSeconds: max(seconds, 0),
            totalSeconds: max(totalSeconds, seconds, 1),
            isPaused: true
        )

        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() {
        let activities = Activity<FocusTimerAttributes>.activities
        guard !activities.isEmpty else { return }

        Task {
            for activity in activities {
                let finalState = FocusTimerAttributes.ContentState(
                    endDate: Date(),
                    remainingSeconds: 0,
                    totalSeconds: 1,
                    isPaused: false
                )
                let content = ActivityContent(state: finalState, staleDate: Date())
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
    }
}
