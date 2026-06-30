import SwiftUI

struct DateNavigationBar: View {
    let onPrevious: () -> Void
    let onToday: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: SegmentedControlMetrics.statsGap) {
            DateNavCell(
                position: .leading,
                size: SegmentedControlMetrics.dateNavChevron,
                action: onPrevious
            ) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
            }

            DateNavCell(
                position: .middle,
                size: SegmentedControlMetrics.dateNavToday,
                action: onToday
            ) {
                Text(AppStrings.Stats.today)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
            }

            DateNavCell(
                position: .trailing,
                size: SegmentedControlMetrics.dateNavChevron,
                action: onNext
            ) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
    }
}

private struct DateNavCell<Label: View>: View {
    enum Position {
        case leading, middle, trailing
    }

    let position: Position
    let size: CGSize
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        PressableCell(
            size: size,
            shape: cellShape,
            fill: AppColors.controlFill,
            pressedFill: AppColors.controlPressed,
            isInteractionDisabled: false,
            action: action,
            label: label
        )
    }

    private var cellShape: UnevenRoundedRectangle {
        let radius = ControlCorners.standalone
        switch position {
        case .leading:
            return UnevenRoundedRectangle(
                topLeadingRadius: radius,
                bottomLeadingRadius: radius,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
        case .middle:
            return UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
        case .trailing:
            return UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: radius,
                topTrailingRadius: radius,
                style: .continuous
            )
        }
    }
}
