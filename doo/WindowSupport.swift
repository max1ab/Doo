import AppKit
import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            window = view.window
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            window = nsView.window
        }
    }
}

struct TitlebarAccessory: NSViewRepresentable {
    let isPinned: Bool
    let onAdd: () -> Void
    let onTogglePin: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.attachIfNeeded(to: view)
        context.coordinator.update(
            isPinned: isPinned,
            onAdd: onAdd,
            onTogglePin: onTogglePin
        )
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.attachIfNeeded(to: nsView)
        context.coordinator.update(
            isPinned: isPinned,
            onAdd: onAdd,
            onTogglePin: onTogglePin
        )
    }

    final class Coordinator {
        private let accessory = NSTitlebarAccessoryViewController()
        private let hostingView = NSHostingView(
            rootView: TitlebarButtons(isPinned: false, onAdd: {}, onTogglePin: {})
        )
        private weak var window: NSWindow?

        init() {
            accessory.layoutAttribute = .trailing
            accessory.view = hostingView
            hostingView.translatesAutoresizingMaskIntoConstraints = false
        }

        func attachIfNeeded(to anchorView: NSView) {
            DispatchQueue.main.async {
                guard let window = anchorView.window else { return }
                guard self.window !== window else { return }

                self.window = window
                if self.accessory.parent == nil {
                    window.addTitlebarAccessoryViewController(self.accessory)
                }
            }
        }

        func update(isPinned: Bool, onAdd: @escaping () -> Void, onTogglePin: @escaping () -> Void) {
            hostingView.rootView = TitlebarButtons(
                isPinned: isPinned,
                onAdd: onAdd,
                onTogglePin: onTogglePin
            )
            hostingView.frame.size = hostingView.fittingSize
            accessory.view.frame.size = hostingView.fittingSize
        }
    }
}

private struct TitlebarButtons: View {
    let isPinned: Bool
    let onAdd: () -> Void
    let onTogglePin: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            TitlebarIconButton(
                systemName: "plus",
                accessibilityLabel: "新建 Todo",
                action: onAdd
            )
            .help("新建 Todo")

            TitlebarIconButton(
                systemName: isPinned ? "pin.fill" : "pin",
                accessibilityLabel: isPinned ? "取消置顶" : "置顶显示",
                isActive: isPinned,
                action: onTogglePin
            )
            .help(isPinned ? "取消置顶" : "置顶显示")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

private struct TitlebarIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var isActive = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 24)
                .foregroundStyle(foregroundColor)
                .background(backgroundShape)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var foregroundColor: Color {
        if isActive {
            return .white
        }
        return .primary.opacity(isHovering ? 0.95 : 0.8)
    }

    @ViewBuilder
    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {
        if isActive {
            return Color.accentColor
        }
        if isHovering {
            return Color.primary.opacity(0.1)
        }
        return .clear
    }
}
