//
//  ContentView.swift
//  doo
//
//  Created by r00t on 2025/7/16.
//

import AppKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            TodoView()
        }
    }
}

struct TodoItem {
    let id = UUID()
    var over = false
    var content = ""
    
    init(_ content: String = "",_ over: Bool = false) {
        self.content = content
        self.over = over
    }
}

var exampleTodos = [
    TodoItem("吃饭"),
    TodoItem("睡觉"),
    TodoItem("打豆豆"),
    TodoItem("完成代码和视频剪辑"),
    TodoItem("看书",true),
    TodoItem("",true)
]

struct TodoView: View {
    @State private var todoItems = [TodoItem()]
//    @State private var todoItems = exampleTodos
//    @State private var focusedID: UUID?  // 跟踪当前焦点项
    @FocusState private var focusedField: UUID?  // SwiftUI 焦点管理
    @State private var window: NSWindow?
    @State private var isPinned = false
    
    
    var body: some View {
        VStack {
            List {
                ForEach(Array(zip(todoItems.indices, todoItems)), id: \.1.id) { index, item in
                    TodoItemView(
                        item: $todoItems[index],
                        onComplete: {
                            moveToEndIfDone(index: index)
                        },
                        onEnter: {
                            addTodoItem(index: index)
                        }
                    )
                    .focused($focusedField, equals: item.id)  // 绑定焦点状态
//                    .onChange(of: item.content) {
//                        if item.content.isEmpty && index != todoItems.count - 1 {
//                            deleteItem(at: index)
//                        }
//                    }
                }
                .onMove(perform: move)
            }
        }
        .background(WindowAccessor(window: $window))
        .background(
            TitlebarAccessory(
                isPinned: isPinned,
                onAdd: addTodoFromToolbar,
                onTogglePin: togglePin
            )
        )
        .onAppear {
            focusedField = todoItems.first?.id
        }
        .onChange(of: window) { _, newWindow in
            guard let newWindow else { return }
            configureWindowChrome(newWindow)
            isPinned = newWindow.level == .floating
        }
        //        .onChange(of: focusedID) { newValue in
//            focusedID = newValue
//        }
        // 键盘事件监听
        .onKeyPress(.upArrow) { 
            moveFocusUp()
            return .handled
        }
        .onKeyPress(.downArrow) { 
            moveFocusDown()
            return .handled
        }
        .onKeyPress(.tab) { 
            moveFocusDown()
            return .handled
        }
    }
    
    // 排序逻辑
    func move(from source: IndexSet, to destination: Int) {
        todoItems.move(fromOffsets: source, toOffset: destination)
    }
    
    // 自动将完成项移到最后
    func moveToEndIfDone(index: Int) {
        guard index < todoItems.count && todoItems[index].over else { return }
        
        // 计算已完成项目的数量（从末尾开始）
        var completedCount = 0
        for item in todoItems.reversed() {
            if item.over {
                completedCount += 1
            } else {
                break
            }
        }
        
        // 安全地移动项目
        let targetIndex = todoItems.count - completedCount
        if index < targetIndex - 1 {
            withAnimation {
                let item = todoItems.remove(at: index)
                todoItems.insert(item, at: targetIndex - 1)
            }
        }
    }
    
    // 添加新todo
    func addTodoItem(index: Int) {
        guard !todoItems[index].content.isEmpty else { return }
        
        let newItem = TodoItem()
        todoItems.insert(newItem, at: index + 1)
        
        // 延迟设置焦点确保视图已更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = newItem.id
        }
    }

    private func addTodoFromToolbar() {
        let newItem = TodoItem()
        todoItems.insert(newItem, at: todoItems.startIndex)

        DispatchQueue.main.async {
            focusedField = newItem.id
        }
    }

    private func togglePin() {
        guard let window else { return }

        isPinned.toggle()
        window.level = isPinned ? .floating : .normal
    }

    private func configureWindowChrome(_ window: NSWindow) {
        if let closeButton = window.standardWindowButton(.closeButton) {
            closeButton.isHidden = false
            closeButton.target = NSApp
            closeButton.action = #selector(NSApplication.terminate(_:))
        }

        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    // 焦点上移
    private func moveFocusUp() {
        guard let currentID = focusedField,
              let currentIndex = todoItems.firstIndex(where: { $0.id == currentID }),
              currentIndex > 0 else { return }
        
        focusedField = todoItems[currentIndex - 1].id
    }
    
    // 焦点下移
    private func moveFocusDown() {
        guard let currentID = focusedField else {
//            focusedField = todoItems.first?.id
            return
        }
        
        if let currentIndex = todoItems.firstIndex(where: { $0.id == currentID }) {
            if currentIndex < todoItems.count - 1 {
                focusedField = todoItems[currentIndex + 1].id
            } else if todoItems.last?.content.isEmpty == false {
                addTodoItem(index: currentIndex)
            }
        }
    }
    // 删除空项
    private func deleteItem(at index: Int) {
        guard todoItems.count > 1 else { return }
        todoItems.remove(at: index)
        
        // 焦点转移到相邻项
        if index < todoItems.count {
            focusedField = todoItems[index].id
        } else if !todoItems.isEmpty {
            focusedField = todoItems.last?.id
        }
    }
}

private struct WindowAccessor: NSViewRepresentable {
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

private struct TitlebarAccessory: NSViewRepresentable {
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

struct TodoItemView: View {
    @Binding var item: TodoItem
    @FocusState private var isTextFieldFocused: Bool
    
    var onComplete: () -> Void
    var onEnter: () -> Void
    
    var body: some View {
        HStack {
            if item.over {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        item.over = !item.over
                    }
                Text(item.content)
                    .strikethrough(true, color: .gray)
                    .foregroundStyle(.gray)
                    .padding(2)
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                    .onTapGesture {
                        item.over = !item.over
                        onComplete()
                    }
                TextField("wtf", text: $item.content)
                    .autocorrectionDisabled(true)
                    .strikethrough(item.over)
                    .disabled(item.over)
                    .onSubmit(onEnter)
                    .padding(2)
                    .focused($isTextFieldFocused)
            }
        }
    }
}

#Preview {
    TodoView()
}
