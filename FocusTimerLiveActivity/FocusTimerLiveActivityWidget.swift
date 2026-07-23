import ActivityKit
import SwiftUI
import WidgetKit

struct FocusTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            FocusTimerProgressLayout(state: context.state)
                .frame(maxWidth: .infinity)
                .frame(height: 68)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    FocusTimerProgressLayout(state: context.state)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .padding(.horizontal, 22)
                }
            } compactLeading: {
                FocusTimerCircularProgress(state: context.state)
                    .frame(width: 20, height: 20)
            } compactTrailing: {
                FocusTimerTimeText(state: context.state)
                    .font(.caption.monospacedDigit())
                    .frame(width: 48)
            } minimal: {
                FocusTimerTimeText(state: context.state)
                    .font(.caption2.monospacedDigit())
            }
        }
    }
}

private struct FocusTimerProgressLayout: View {
    let state: FocusTimerAttributes.ContentState

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("live_activity_title")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                FocusTimerTimeText(state: state)
                    .font(.subheadline.monospacedDigit())
                    .frame(width: 52, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)

            FocusTimerLinearProgress(state: state)
                .frame(maxHeight: .infinity, alignment: .center)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct FocusTimerLinearProgress: View {
    let state: FocusTimerAttributes.ContentState

    var body: some View {
        FocusTimerProgressContent(state: state)
            .labelsHidden()
            .progressViewStyle(.linear)
            .tint(Color.green)
            .shadow(color: Color.green.opacity(0.55), radius: 3)
            .scaleEffect(x: -1, y: 1)
    }
}

private struct FocusTimerCircularProgress: View {
    let state: FocusTimerAttributes.ContentState

    var body: some View {
        FocusTimerProgressContent(state: state)
            .labelsHidden()
            .progressViewStyle(.circular)
            .tint(Color.green)
            .shadow(color: Color.green.opacity(0.55), radius: 2)
    }
}

private struct FocusTimerProgressContent: View {
    let state: FocusTimerAttributes.ContentState

    private var progressStartDate: Date {
        state.endDate.addingTimeInterval(-TimeInterval(max(state.totalSeconds, 1)))
    }

    private var progressEndDate: Date {
        max(state.endDate, progressStartDate)
    }

    var body: some View {
        Group {
            if state.isPaused {
                ProgressView(
                    value: Double(max(state.remainingSeconds, 0)),
                    total: Double(max(state.totalSeconds, 1))
                ) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            } else {
                ProgressView(
                    timerInterval: progressStartDate...progressEndDate,
                    countsDown: true
                ) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
        }
    }
}

private struct FocusTimerTimeText: View {
    let state: FocusTimerAttributes.ContentState

    var body: some View {
        Group {
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
    }

    private func formattedTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", max(seconds, 0) / 60, max(seconds, 0) % 60)
    }
}
