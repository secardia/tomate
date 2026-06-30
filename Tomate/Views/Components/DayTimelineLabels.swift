import SwiftUI

struct DayTimelineLabels: View {
    let layout: DayTimelineLayout

    var body: some View {
        let placements = layout.labelPlacements()

        ZStack(alignment: .topLeading) {
            ForEach(placements) { placement in
                Text(placement.text)
                    .fixedSize()
                    .position(
                        x: placement.centerX,
                        y: TimelineTimeLabelLayout.fontSize / 2
                    )
            }
        }
        .frame(width: layout.totalWidth, height: TimelineTimeLabelLayout.fontSize)
        .font(.system(size: TimelineTimeLabelLayout.fontSize))
        .foregroundStyle(AppColors.textSecondary)
    }
}
