import SwiftUI

struct WeekDayColumn: View {
    let focusCount: Int
    let restCount: Int
    let dayLabel: String
    let isToday: Bool
    let isPastOrToday: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 8) {
                if focusCount > 0 {
                    Text("\(focusCount)")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.focus)
                }

                if restCount > 0 {
                    Text("\(restCount)")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.rest)
                }
            }

            Spacer(minLength: 0)

            Text(dayLabel)
                .font(.system(size: 12, weight: isToday ? .bold : .regular))
                .foregroundStyle(isPastOrToday ? AppColors.textPrimary : AppColors.textSecondary)
                .frame(height: 14, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
