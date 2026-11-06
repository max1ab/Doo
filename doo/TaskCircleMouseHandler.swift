import AppKit
import SwiftUI

// SwiftUI tap gestures do not expose the secondary mouse button on macOS 15.
struct TaskCircleMouseHandler: NSViewRepresentable {
    var onClick: () -> Void
    var onRightClick: () -> Void

    func makeNSView(context: Context) -> MouseView {
        MouseView()
    }

    func updateNSView(_ view: MouseView, context: Context) {
        view.onClick = onClick
        view.onRightClick = onRightClick
    }

    final class MouseView: NSView {
        var onClick: (() -> Void)?
        var onRightClick: (() -> Void)?

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            onClick?()
        }

        override func rightMouseDown(with event: NSEvent) {
            onRightClick?()
        }
    }
}
