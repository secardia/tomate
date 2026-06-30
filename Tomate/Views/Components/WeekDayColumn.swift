import SwiftUI

struct WeekDayColumn: View {
    let focusCount: Int
    let restCount: Int
    let dayLabel: String
    let isToday: Bool
    let isPastOrToday: Bool

    private var dayLabelColor: Color {
        if isToday {
            AppColors.textPrimary
        } else if isPastOrToday {
            AppColors.weekPastDayLabel
        } else {
            AppColors.textSecondary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 8) {
                if focusCount > 0 {
                    Text("\(focusCount)")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(SessionType.focus.accentColor)
                }

                if restCount > 0 {
                    Text("\(restCount)")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(SessionType.rest.accentColor)
                }
            }

            Spacer(minLength: 0)

            Text(dayLabel)
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                .foregroundStyle(dayLabelColor)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minHeight: 15, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
