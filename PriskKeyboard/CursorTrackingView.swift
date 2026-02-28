// Copyright (c) 2026 Prisk Contributors
// Licensed under the Apache License, Version 2.0

import UIKit

// MARK: — CursorTrackingView
// Overlay on the spacebar that detects horizontal drag for cursor movement.
// Apple-style: dragging left/right moves insertion point.

final class CursorTrackingView: UIView {

    var onCursorOffset: ((Int) -> Void)?  // negative = left, positive = right

    private var initialX: CGFloat = 0
    private var accumulatedOffset: CGFloat = 0
    private let pixelsPerStep: CGFloat = 10

    // MARK: — Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(pan)
    }

    // MARK: — Gesture

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialX = gesture.translation(in: self).x
            accumulatedOffset = 0
        case .changed:
            let currentX = gesture.translation(in: self).x
            let delta = currentX - initialX
            let steps = Int(delta / pixelsPerStep)
            let newAccum = CGFloat(steps) * pixelsPerStep
            if newAccum != accumulatedOffset {
                let stepDelta = Int((newAccum - accumulatedOffset) / pixelsPerStep)
                accumulatedOffset = newAccum
                onCursorOffset?(stepDelta)
                UIDevice.current.playInputClick()
            }
        case .ended, .cancelled, .failed:
            accumulatedOffset = 0
        default:
            break
        }
    }
}
