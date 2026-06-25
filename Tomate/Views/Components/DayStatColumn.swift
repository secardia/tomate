import SwiftUI

struct DayStatColumn: View {
    let title: String
    let count: Int
    let duration: String
    let accent: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(accent)

            Text("\(count)")
                .font(.system(size: 40, weight: .medium, design: .rounded))
                .foregroundStyle(accent)
                .monospacedDigit()

            Text(duration)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}
