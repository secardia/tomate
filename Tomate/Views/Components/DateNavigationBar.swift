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

private struct DateNavCell: View {
    enum Position {
        case leading, middle, trailing
    }

    let position: Position
    let size: CGSize
    let action: () -> Void
    let label: AnyView

    @State private var isPressed = false

    init(
        position: Position,
        size: CGSize,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> some View
    ) {
        self.position = position
        self.size = size
        self.action = action
        self.label = AnyView(label())
    }

    var body: some View {
        cellShape
            .fill(isPressed ? AppColors.controlPressed : AppColors.controlFill)
            .frame(width: size.width, height: size.height)
            .overlay { label }
            .contentShape(cellShape)
            .gesture(pressGesture)
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

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in isPressed = true }
            .onEnded { _ in
                isPressed = false
                action()
            }
    }
}
