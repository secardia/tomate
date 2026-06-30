import SwiftUI

/// Fixed-size cell with press feedback. Shape, colors, and interaction are caller-defined.
struct PressableCell<S: Shape, Label: View>: View {
    let size: CGSize
    let shape: S
    let fill: Color
    let pressedFill: Color
    let isInteractionDisabled: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isPressed = false

    var body: some View {
        shape
            .fill(backgroundColor)
            .frame(width: size.width, height: size.height)
            .overlay { label() }
            .contentShape(shape)
            .gesture(pressGesture)
    }

    private var backgroundColor: Color {
        guard !isInteractionDisabled, isPressed else { return fill }
        return pressedFill
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isInteractionDisabled else { return }
                isPressed = true
            }
            .onEnded { _ in
                guard !isInteractionDisabled else { return }
                isPressed = false
                action()
            }
    }
}
