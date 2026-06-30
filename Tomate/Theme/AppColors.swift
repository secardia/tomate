import SwiftUI

enum AppColors {
    static let background = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let surface = Color(red: 0.17, green: 0.17, blue: 0.18)
    /// Action buttons (timer, date navigation) — slightly lighter than surface.
    static let controlFill = Color(red: 0.21, green: 0.21, blue: 0.22)
    static let focus = Color(red: 0.90, green: 0.47, blue: 0.45)
    static let focusMuted = Color(red: 0.32, green: 0.18, blue: 0.18)
    static let rest = Color(red: 0.55, green: 0.58, blue: 0.85)
    static let restMuted = Color(red: 0.18, green: 0.20, blue: 0.32)
    /// Primary text — very light gray, not pure white.
    static let textPrimary = Color(white: 0.74)
    static let textSecondary = Color(white: 0.50)
    static let timelineInactive = Color(red: 0.16, green: 0.16, blue: 0.17)
    /// Timer pause gap on the day timeline.
    static let timelineGap = Color(white: 0.22)
    static let divider = Color(white: 0.20)
    static let segmentSelected = Color(white: 0.25)
    static let segmentPressed = Color(white: 0.32)
    static let controlPressed = Color(white: 0.28)
}

/// Corner radii for nested controls: R_outer = R_inner + inset.
enum ControlCorners {
    static let inset: CGFloat = 2
    static let inner: CGFloat = 8
    static let outer: CGFloat = inner + inset
    static let standalone: CGFloat = 10
}

enum AppLayoutMetrics {
    /// Horizontal content margin.
    static let contentMargin: CGFloat = 16
    /// Top bar margin (half of contentMargin).
    static let topBarMargin: CGFloat = 8
    static let topBarContentHeight: CGFloat = 30
    static var topBarInsetHeight: CGFloat { contentMargin + topBarContentHeight }

    static let timerContentTopPadding: CGFloat = 30
    static let timerVerticalShiftRatio: CGFloat = 0.30
    static let progressBarHeight: CGFloat = 6
    /// Gray margin on the left/right of the timeline (fraction of width).
    static let timelineContentInsetFraction: CGFloat = 0.05
    static let timerControlsHeight: CGFloat = 68

    static var timerBottomInsetHeight: CGFloat {
        progressBarHeight
    }

    static var timerMinimumContentHeight: CGFloat {
        timerContentTopPadding + 31 + 74 + 16 + timerControlsHeight + 12
    }

    /// Minimum window height — must cover top bar + content + timer bottom bar.
    static let minimumWindowHeight: CGFloat = 300
}
