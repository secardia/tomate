import Foundation

protocol SessionRecording: AnyObject {
    func record(type: SessionType, start: Date, end: Date)
    func recordTimeline(_ interval: TimelineInterval)
}
