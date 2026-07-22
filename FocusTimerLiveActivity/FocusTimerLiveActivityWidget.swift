import ActivityKit
import SwiftUI
import WidgetKit

struct FocusTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            FocusTimerLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("live_activity_title")
                }

                DynamicIslandExpandedRegion(.trailing) {
                    timerText(for: context.state)
                        .font(.title3.monospacedDigit())
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.isPaused ? "live_activity_paused" : "live_activity_focusing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                timerText(for: context.state)
                    .font(.caption.monospacedDigit())
                    .frame(width: 48)
            } minimal: {
                timerText(for: context.state)
                    .font(.caption2.monospacedDigit())
            }
            .keylineTint(.red)
        }
    }

    @ViewBuilder
    private func timerText(for state: FocusTimerAttributes.ContentState) -> some View {
        if state.isPaused {
            Text(formattedTime(state.remainingSeconds))
                .monospacedDigit()
        } else {
            Text(
                timerInterval: Date.now...max(state.endDate, Date.now),
                countsDown: true,
                showsHours: false
            )
            .monospacedDigit()
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", max(seconds, 0) / 60, max(seconds, 0) % 60)
    }
}

private struct FocusTimerLockScreenView: View {
    let state: FocusTimerAttributes.ContentState

    private var secondaryTextColor: Color {
        Color.black
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("live_activity_title")
                    .font(.headline)
                Text(state.isPaused ? "live_activity_paused" : "live_activity_focusing")
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
            }

            Spacer()

            timerText
                .font(.system(size: 28, weight: .light, design: .monospaced))
        }
        .padding()
        .foregroundStyle(Color.black)
        .activityBackgroundTint(Color.white)
        .activitySystemActionForegroundColor(Color.black)
    }

    @ViewBuilder
    private var timerText: some View {
        if state.isPaused {
            Text(formattedTime(state.remainingSeconds))
                .monospacedDigit()
        } else {
            Text(
                timerInterval: Date.now...max(state.endDate, Date.now),
                countsDown: true,
                showsHours: false
            )
            .monospacedDigit()
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", max(seconds, 0) / 60, max(seconds, 0) % 60)
    }
}
