import SwiftUI
import XCTest
@testable import Tomate

@MainActor
final class ScreenshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ScreenshotFixtures.registerPreferences()
    }

    func testGenerateScreenshots() throws {
        try renderTimerRunning()
        try renderStatsDay()
        try renderStatsDayLive()
        try renderStatsWeek()
    }

    private func renderTimerRunning() throws {
        let scene = ScreenshotFixtures.makeTimerRunningScene()
        try ScreenshotRenderer.renderWindow(
            AppScreenshotView(
                navigation: scene.navigation,
                store: scene.store,
                timer: scene.timer
            ),
            title: "Tomate",
            named: "timer-running.png"
        )
    }

    private func renderStatsDay() throws {
        let scene = ScreenshotFixtures.makeStatsDayScene()
        try ScreenshotRenderer.renderWindow(
            AppScreenshotView(
                navigation: scene.navigation,
                store: scene.store,
                timer: scene.timer
            ),
            title: "Tomate",
            named: "stats-day.png"
        )
    }

    private func renderStatsDayLive() throws {
        let scene = ScreenshotFixtures.makeStatsDayLiveScene()
        try ScreenshotRenderer.renderWindow(
            AppScreenshotView(
                navigation: scene.navigation,
                store: scene.store,
                timer: scene.timer
            ),
            title: "Tomate",
            named: "stats-day-live.png"
        )
    }

    private func renderStatsWeek() throws {
        let scene = ScreenshotFixtures.makeStatsWeekScene()
        try ScreenshotRenderer.renderWindow(
            AppScreenshotView(
                navigation: scene.navigation,
                store: scene.store,
                timer: scene.timer
            )
            .environment(\.statsToday, ScreenshotFixtures.weekReferenceToday),
            title: "Tomate",
            named: "stats-week.png"
        )
    }
}
