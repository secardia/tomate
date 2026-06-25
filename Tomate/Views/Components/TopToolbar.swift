import SwiftUI

struct TopToolbar: View {
    let screen: AppScreen
    let onTimerTap: () -> Void
    let onStatsTap: () -> Void

    var body: some View {
        SegmentedControlGroup {
            HStack(spacing: 2) {
                SegmentedControlCell(
                    size: SegmentedControlMetrics.toolbarCell,
                    isActive: screen == .timer,
                    action: onTimerTap
                ) {
                    Image(systemName: "circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(screen == .timer ? AppColors.textPrimary : AppColors.textSecondary)
                }
                SegmentedControlCell(
                    size: SegmentedControlMetrics.toolbarCell,
                    isActive: screen == .stats,
                    action: onStatsTap
                ) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(screen == .stats ? AppColors.textPrimary : AppColors.textSecondary)
                }
            }
        }
    }
}
