import SwiftUI

struct StatsDateNavigator: View {
    let title: String
    let onPrevious: () -> Void
    let onToday: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            DateNavigationBar(
                onPrevious: onPrevious,
                onToday: onToday,
                onNext: onNext
            )

            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
    }
}
