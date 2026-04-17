import AppKit
import SwiftUI

struct TodoView: View {
    @State private var todoItems = [TodoItem()]
    @State private var todoStore = TodoMarkdownStore()
    @FocusState private var focusedField: UUID?
    @State private var window: NSWindow?
    @State private var isPinned = false
    @State private var hasLoadedToday = false
    @State private var todaySectionExists = false

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
                    .focused($focusedField, equals: item.id)
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
            loadTodayItemsIfNeeded()
            focusedField = todoItems.first?.id
        }
        .onChange(of: todoItems) { _, newItems in
            guard hasLoadedToday else { return }
            todaySectionExists = todoStore.syncToday(
                with: newItems,
                sectionExists: todaySectionExists
            )
        }
        .onChange(of: window) { _, newWindow in
            guard let newWindow else { return }
            configureWindowChrome(newWindow)
            isPinned = newWindow.level == .floating
        }
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

    private func move(from source: IndexSet, to destination: Int) {
        todoItems.move(fromOffsets: source, toOffset: destination)
    }

    private func loadTodayItemsIfNeeded() {
        guard !hasLoadedToday else { return }

        let snapshot = todoStore.loadToday()
        todaySectionExists = snapshot.sectionExists
        todoItems = snapshot.items.isEmpty ? [TodoItem()] : snapshot.items
        hasLoadedToday = true
    }

    private func moveToEndIfDone(index: Int) {
        guard index < todoItems.count && todoItems[index].over else { return }

        var completedCount = 0
        for item in todoItems.reversed() {
            if item.over {
                completedCount += 1
            } else {
                break
            }
        }

        let targetIndex = todoItems.count - completedCount
        if index < targetIndex - 1 {
            withAnimation {
                let item = todoItems.remove(at: index)
                todoItems.insert(item, at: targetIndex - 1)
            }
        }
    }

    private func addTodoItem(index: Int) {
        guard !todoItems[index].content.isEmpty else { return }

        let newItem = TodoItem()
        todoItems.insert(newItem, at: index + 1)

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

    private func moveFocusUp() {
        guard let currentID = focusedField,
              let currentIndex = todoItems.firstIndex(where: { $0.id == currentID }),
              currentIndex > 0 else { return }

        focusedField = todoItems[currentIndex - 1].id
    }

    private func moveFocusDown() {
        guard let currentID = focusedField else { return }

        if let currentIndex = todoItems.firstIndex(where: { $0.id == currentID }) {
            if currentIndex < todoItems.count - 1 {
                focusedField = todoItems[currentIndex + 1].id
            } else if todoItems.last?.content.isEmpty == false {
                addTodoItem(index: currentIndex)
            }
        }
    }
}

struct TodoView_Previews: PreviewProvider {
    static var previews: some View {
        TodoView()
    }
}
