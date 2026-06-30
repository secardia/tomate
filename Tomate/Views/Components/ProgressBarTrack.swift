import SwiftUI

/// Horizontal track with a caller-defined fill layer. Height and track color are parameterized.
struct ProgressBarTrack<Fill: View>: View {
    let trackColor: Color
    let height: CGFloat
    let fill: (CGFloat) -> Fill

    init(
        trackColor: Color,
        height: CGFloat = AppLayoutMetrics.progressBarHeight,
        @ViewBuilder fill: @escaping (CGFloat) -> Fill
    ) {
        self.trackColor = trackColor
        self.height = height
        self.fill = fill
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(trackColor)
                fill(geometry.size.width)
            }
        }
        .frame(height: height)
    }
}

/// Full-width chrome band pinned to a window edge.
struct EdgeChrome<Content: View>: View {
    var background: Color = AppColors.background
    var padding: EdgeInsets = EdgeInsets()
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(background)
    }
}
