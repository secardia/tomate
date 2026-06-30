import SwiftUI

enum SegmentedControlMetrics {
    static let statsGap: CGFloat = 2
    static let statsCellSize = CGSize(width: 76, height: 26)

    static let toolbarCell = CGSize(width: 30, height: 26)
    static let periodCell = statsCellSize
    static let dateNavChevron = CGSize(width: 28, height: 26)
    static let dateNavToday = CGSize(width: 92, height: 26)
}

/// Segmented cell: fixed hitbox equals the selection rectangle.
struct SegmentedControlCell: View {
    let size: CGSize
    let isActive: Bool
    let action: () -> Void
    let label: AnyView

    init(
        size: CGSize,
        isActive: Bool,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> some View
    ) {
        self.size = size
        self.isActive = isActive
        self.action = action
        self.label = AnyView(label())
    }

    var body: some View {
        PressableCell(
            size: size,
            shape: RoundedRectangle(cornerRadius: ControlCorners.inner, style: .continuous),
            fill: isActive ? AppColors.segmentSelected : AppColors.surface,
            pressedFill: AppColors.segmentPressed,
            isInteractionDisabled: isActive,
            action: action,
            label: { label }
        )
    }
}

struct SegmentedControlGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(ControlCorners.inset)
            .background(
                RoundedRectangle(cornerRadius: ControlCorners.outer, style: .continuous)
                    .fill(AppColors.surface)
            )
    }
}
