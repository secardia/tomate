import XCTest
@testable import Tomate

final class TimelineTimeLabelLayoutTests: XCTestCase {
    private func width(_ text: String) -> CGFloat {
        TimelineTimeLabelLayout.measuredWidth(for: text)
    }

    private func assertNoOverlap(
        _ placements: [TimelineTimeLabelPlacement],
        availableWidth: CGFloat,
        horizontalPadding: CGFloat = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sorted = placements.sorted { $0.centerX < $1.centerX }
        for index in 1..<sorted.count {
            let previous = sorted[index - 1]
            let current = sorted[index]
            let previousHalf = width(previous.text) / 2
            let currentHalf = width(current.text) / 2
            XCTAssertGreaterThanOrEqual(
                current.centerX - currentHalf,
                previous.centerX + previousHalf + TimelineTimeLabelLayout.minimumSpacing - 0.01,
                file: file,
                line: line
            )
        }

        for placement in sorted {
            let half = width(placement.text) / 2
            XCTAssertGreaterThanOrEqual(
                placement.centerX,
                horizontalPadding + half - 0.01,
                file: file,
                line: line
            )
            XCTAssertLessThanOrEqual(
                placement.centerX,
                availableWidth - horizontalPadding - half + 0.01,
                file: file,
                line: line
            )
        }
    }

    func testResolveKeepsSeparatedLabelsAtIdealPositions() {
        let placements = TimelineTimeLabelLayout.resolve(
            labels: [
                .init(id: "a", text: "9h00", idealCenterX: 40),
                .init(id: "b", text: "18h00", idealCenterX: 360),
            ],
            availableWidth: 400
        )

        let sorted = placements.sorted { $0.centerX < $1.centerX }
        XCTAssertEqual(sorted[0].centerX, 40, accuracy: 0.01)
        XCTAssertEqual(sorted[1].centerX, 360, accuracy: 0.01)
        assertNoOverlap(placements, availableWidth: 400)
    }

    func testResolveSeparatesOverlappingLabels() {
        let placements = TimelineTimeLabelLayout.resolve(
            labels: [
                .init(id: "a", text: "9h00", idealCenterX: 100),
                .init(id: "b", text: "9h30", idealCenterX: 105),
            ],
            availableWidth: 400
        )

        assertNoOverlap(placements, availableWidth: 400)
        let sorted = placements.sorted { $0.centerX < $1.centerX }
        XCTAssertGreaterThan(sorted[1].centerX, sorted[0].centerX)
    }

    func testResolveSeparatesFourCrowdedLabels() {
        let placements = TimelineTimeLabelLayout.resolve(
            labels: [
                .init(id: "dayStart", text: "9h00", idealCenterX: 20),
                .init(id: "pauseStart", text: "12h00", idealCenterX: 100),
                .init(id: "pauseEnd", text: "13h00", idealCenterX: 108),
                .init(id: "dayEnd", text: "18h00", idealCenterX: 380),
            ],
            availableWidth: 400
        )

        XCTAssertEqual(placements.count, 4)
        assertNoOverlap(placements, availableWidth: 400)
    }

    func testResolveClampsEdgeLabelsInsideBounds() {
        let padding = AppLayoutMetrics.topBarMargin
        let placements = TimelineTimeLabelLayout.resolve(
            labels: [
                .init(id: "a", text: "9h00", idealCenterX: 0),
                .init(id: "b", text: "18h00", idealCenterX: 400),
            ],
            availableWidth: 400,
            horizontalPadding: padding
        )

        assertNoOverlap(placements, availableWidth: 400, horizontalPadding: padding)
        let sorted = placements.sorted { $0.centerX < $1.centerX }
        XCTAssertGreaterThanOrEqual(sorted[0].centerX, padding + width("9h00") / 2 - 0.01)
        XCTAssertLessThanOrEqual(sorted[1].centerX, 400 - padding - width("18h00") / 2 + 0.01)
    }

    func testSeparationMovesSplitsEquallyWhenBothCanMove() {
        let moves = TimelineTimeLabelLayout.separationMoves(
            deficit: 10,
            canMoveLeft: 20,
            canMoveRight: 20
        )
        XCTAssertEqual(moves.left, 5, accuracy: 0.01)
        XCTAssertEqual(moves.right, 5, accuracy: 0.01)
    }

    func testSeparationMovesShiftsOnlyMobileLabelWhenOtherPinnedRight() {
        let moves = TimelineTimeLabelLayout.separationMoves(
            deficit: 10,
            canMoveLeft: 20,
            canMoveRight: 0
        )
        XCTAssertEqual(moves.left, 10, accuracy: 0.01)
        XCTAssertEqual(moves.right, 0, accuracy: 0.01)
    }

    func testResolveSplitsMovablePairEqually() {
        let labelWidth = width("9h00")
        let overlap = labelWidth - 2
        let placements = TimelineTimeLabelLayout.resolve(
            labels: [
                .init(id: "left", text: "9h00", idealCenterX: 100),
                .init(id: "right", text: "9h00", idealCenterX: 100 + overlap),
            ],
            availableWidth: 400
        )

        let sorted = placements.sorted { $0.centerX < $1.centerX }
        let expectedShift = (labelWidth + TimelineTimeLabelLayout.minimumSpacing - overlap) / 2
        XCTAssertEqual(sorted[0].centerX, 100 - expectedShift, accuracy: 0.5)
        XCTAssertEqual(sorted[1].centerX, 100 + overlap + expectedShift, accuracy: 0.5)
        assertNoOverlap(placements, availableWidth: 400)
    }

    func testResolveShiftsUnpinnedLabelWhenRightLabelIsPinned() {
        let padding: CGFloat = 0
        let endWidth = width("18h00")
        let endCenter = 400 - padding - endWidth / 2
        let pauseWidth = width("13h00")
        let overlap: CGFloat = 6
        let placements = TimelineTimeLabelLayout.resolve(
            labels: [
                .init(id: "dayStart", text: "9h00", idealCenterX: 30),
                .init(id: "pauseStart", text: "12h00", idealCenterX: 200),
                .init(id: "pauseEnd", text: "13h00", idealCenterX: endCenter - pauseWidth / 2 + overlap),
                .init(id: "dayEnd", text: "18h00", idealCenterX: endCenter),
            ],
            availableWidth: 400,
            horizontalPadding: padding
        )

        let byID = Dictionary(uniqueKeysWithValues: placements.map { ($0.id, $0.centerX) })
        XCTAssertEqual(byID["dayEnd"] ?? 0, endCenter, accuracy: 0.01)
        XCTAssertLessThan(byID["pauseEnd"] ?? 0, endCenter - pauseWidth / 2)
        assertNoOverlap(placements, availableWidth: 400, horizontalPadding: padding)
    }
}
