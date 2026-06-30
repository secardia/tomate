import AppKit
import Foundation

struct TimelineTimeLabelSpec: Identifiable, Equatable {
    let id: String
    let text: String
    let idealCenterX: CGFloat
}

struct TimelineTimeLabelPlacement: Identifiable, Equatable {
    let id: String
    let text: String
    let centerX: CGFloat
}

enum TimelineTimeLabelLayout {
    static let fontSize: CGFloat = 11
    static let minimumSpacing: CGFloat = 4

    static func measuredWidth(for text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: fontSize)
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    static func resolve(
        labels: [TimelineTimeLabelSpec],
        availableWidth: CGFloat,
        horizontalPadding: CGFloat = 0,
        minimumSpacing: CGFloat = TimelineTimeLabelLayout.minimumSpacing
    ) -> [TimelineTimeLabelPlacement] {
        guard availableWidth > 0, !labels.isEmpty else { return [] }

        struct Item {
            let spec: TimelineTimeLabelSpec
            let width: CGFloat
            var centerX: CGFloat
        }

        var items = labels
            .sorted { $0.idealCenterX < $1.idealCenterX }
            .map { spec in
                Item(
                    spec: spec,
                    width: measuredWidth(for: spec.text),
                    centerX: spec.idealCenterX
                )
            }

        func halfWidth(_ index: Int) -> CGFloat { items[index].width / 2 }

        func bounds(for index: Int) -> (min: CGFloat, max: CGFloat) {
            let half = halfWidth(index)
            let minX = horizontalPadding + half
            let maxX = max(minX, availableWidth - horizontalPadding - half)
            return (minX, maxX)
        }

        func clamp(_ index: Int) {
            let limits = bounds(for: index)
            items[index].centerX = min(max(items[index].centerX, limits.min), limits.max)
        }

        func gap(between leftIndex: Int, and rightIndex: Int) -> CGFloat {
            (items[rightIndex].centerX - halfWidth(rightIndex))
                - (items[leftIndex].centerX + halfWidth(leftIndex))
        }

        func separateAdjacent(leftIndex: Int, rightIndex: Int) -> Bool {
            let spacing = gap(between: leftIndex, and: rightIndex)
            guard spacing < minimumSpacing else { return false }

            let deficit = minimumSpacing - spacing
            let leftLimits = bounds(for: leftIndex)
            let rightLimits = bounds(for: rightIndex)
            let canMoveLeft = items[leftIndex].centerX - leftLimits.min
            let canMoveRight = rightLimits.max - items[rightIndex].centerX
            let moves = separationMoves(
                deficit: deficit,
                canMoveLeft: canMoveLeft,
                canMoveRight: canMoveRight
            )

            guard moves.left > 0 || moves.right > 0 else { return false }

            items[leftIndex].centerX -= moves.left
            items[rightIndex].centerX += moves.right
            return true
        }

        for index in items.indices {
            clamp(index)
        }

        let iterations = max(4, items.count * 4)
        for _ in 0..<iterations {
            var changed = false
            for index in 0..<(items.count - 1) {
                if separateAdjacent(leftIndex: index, rightIndex: index + 1) {
                    changed = true
                }
            }
            for index in stride(from: items.count - 2, through: 0, by: -1) {
                if separateAdjacent(leftIndex: index, rightIndex: index + 1) {
                    changed = true
                }
            }
            if !changed { break }
        }

        return items.map { item in
            TimelineTimeLabelPlacement(
                id: item.spec.id,
                text: item.spec.text,
                centerX: item.centerX
            )
        }
    }

    /// Distributes overlap correction between two movable labels.
    /// Equal split when both can move; otherwise the mobile label absorbs the full deficit.
    static func separationMoves(
        deficit: CGFloat,
        canMoveLeft: CGFloat,
        canMoveRight: CGFloat
    ) -> (left: CGFloat, right: CGFloat) {
        guard deficit > 0 else { return (0, 0) }

        if canMoveRight <= 0 {
            return (min(deficit, canMoveLeft), 0)
        }
        if canMoveLeft <= 0 {
            return (0, min(deficit, canMoveRight))
        }

        var left = min(deficit / 2, canMoveLeft)
        var right = min(deficit / 2, canMoveRight)
        var remaining = deficit - left - right

        if remaining > 0 {
            let extraRight = min(remaining, canMoveRight - right)
            right += extraRight
            remaining -= extraRight
        }
        if remaining > 0 {
            left += min(remaining, canMoveLeft - left)
        }

        return (left, right)
    }
}
