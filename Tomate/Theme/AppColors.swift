import SwiftUI

enum AppColors {
    static let background = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let surface = Color(red: 0.17, green: 0.17, blue: 0.18)
    /// Boutons d'action (timer, navigation date) — un peu plus clair que surface.
    static let controlFill = Color(red: 0.21, green: 0.21, blue: 0.22)
    static let focus = Color(red: 0.90, green: 0.47, blue: 0.45)
    static let focusMuted = Color(red: 0.32, green: 0.18, blue: 0.18)
    static let rest = Color(red: 0.55, green: 0.58, blue: 0.85)
    static let restMuted = Color(red: 0.18, green: 0.20, blue: 0.32)
    /// Texte principal — gris très clair, pas blanc pur.
    static let textPrimary = Color(white: 0.74)
    static let textSecondary = Color(white: 0.50)
    static let timelineInactive = Color(red: 0.16, green: 0.16, blue: 0.17)
    /// Pause du chrono sur la timeline jour.
    static let timelineGap = Color(white: 0.22)
    static let divider = Color(white: 0.20)
    static let segmentSelected = Color(white: 0.25)
    static let segmentPressed = Color(white: 0.32)
    static let controlPressed = Color(white: 0.28)
}

/// Rayons pour contrôles imbriqués : R_extérieur = R_intérieur + inset.
enum ControlCorners {
    static let inset: CGFloat = 2
    static let inner: CGFloat = 8
    static let outer: CGFloat = inner + inset
    static let standalone: CGFloat = 10
}

extension PomodoroPhase {
    var accentColor: Color {
        switch self {
        case .focus: AppColors.focus
        case .rest: AppColors.rest
        }
    }

    var accentMutedColor: Color {
        switch self {
        case .focus: AppColors.focusMuted
        case .rest: AppColors.restMuted
        }
    }
}

enum AppLayoutMetrics {
    /// Marge horizontale du contenu.
    static let contentMargin: CGFloat = 16
    /// Marge de la barre du haut (moitié de contentMargin).
    static let topBarMargin: CGFloat = 8
    static let topBarContentHeight: CGFloat = 30
    static var topBarInsetHeight: CGFloat { contentMargin + topBarContentHeight }

    static let timerContentTopPadding: CGFloat = 30
    static let timerVerticalShiftRatio: CGFloat = 0.30
    static let progressBarHeight: CGFloat = 6
    /// Marge grise à gauche/droite de la timeline (fraction de la largeur).
    static let timelineContentInsetFraction: CGFloat = 0.05
    static let timerControlsHeight: CGFloat = 68

    static var timerBottomInsetHeight: CGFloat {
        progressBarHeight
    }

    static var timerMinimumContentHeight: CGFloat {
        timerContentTopPadding + 31 + 74 + 16 + timerControlsHeight + 12
    }

    /// Hauteur minimale fenêtre — doit couvrir barre haute + contenu + barre basse timer.
    static let minimumWindowHeight: CGFloat = 300
}
