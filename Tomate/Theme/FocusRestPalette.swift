import SwiftUI

enum FocusRestPalette {
    static func accent(isFocus: Bool) -> Color {
        isFocus ? AppColors.focus : AppColors.rest
    }

    static func muted(isFocus: Bool) -> Color {
        isFocus ? AppColors.focusMuted : AppColors.restMuted
    }
}

extension PomodoroPhase {
    var accentColor: Color {
        FocusRestPalette.accent(isFocus: self == .focus)
    }

    var accentMutedColor: Color {
        FocusRestPalette.muted(isFocus: self == .focus)
    }
}

extension TimelineIntervalKind {
    var accentColor: Color {
        FocusRestPalette.accent(isFocus: self == .focus)
    }

    var accentMutedColor: Color {
        FocusRestPalette.muted(isFocus: self == .focus)
    }
}

extension SessionType {
    var accentColor: Color {
        FocusRestPalette.accent(isFocus: self == .focus)
    }

    var accentMutedColor: Color {
        FocusRestPalette.muted(isFocus: self == .focus)
    }
}
