import Foundation

enum TimerRefreshMetrics {
    /// Logical poll interval while the timer runs (display updates only when the shown second changes).
    static let pollInterval: TimeInterval = 1.0 / 20.0
}
