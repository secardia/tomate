import SwiftUI

struct DayTimelineBar: View {
    let layout: DayTimelineLayout

    var body: some View {
        ProgressBarTrack(trackColor: AppColors.timelineInactive) { _ in
            ForEach(layout.barSegments()) { segment in
                Rectangle()
                    .fill(segment.kind.accentColor)
                    .frame(width: segment.width)
                    .offset(x: segment.offsetX)
            }
        }
    }
}
