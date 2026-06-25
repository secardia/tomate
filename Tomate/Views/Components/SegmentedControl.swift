import SwiftUI

enum SegmentedControlMetrics {
    static let statsGap: CGFloat = 2
    static let statsCellSize = CGSize(width: 76, height: 26)

    static let toolbarCell = CGSize(width: 30, height: 26)
    static let periodCell = statsCellSize
    static let dateNavChevron = CGSize(width: 28, height: 26)
    static let dateNavToday = CGSize(width: 92, height: 26)
}

/// Cellule segmentée : hitbox fixe = rectangle de sélection.
struct SegmentedControlCell: View {
    let size: CGSize
    let isActive: Bool
    let action: () -> Void
    let label: AnyView

    @State private var isPressed = false

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
        RoundedRectangle(cornerRadius: ControlCorners.inner, style: .continuous)
            .fill(backgroundColor)
            .frame(width: size.width, height: size.height)
            .overlay { label }
            .contentShape(Rectangle())
            .gesture(pressGesture)
    }

    private var backgroundColor: Color {
        if isActive { return AppColors.segmentSelected }
        if isPressed { return AppColors.segmentPressed }
        return AppColors.surface
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isActive else { return }
                isPressed = true
            }
            .onEnded { _ in
                guard !isActive else { return }
                isPressed = false
                action()
            }
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
