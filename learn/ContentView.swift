//
//  ContentView.swift
//  learn
//
//  Created by r00t on 2025/7/16.
//

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
    //@State private var todoItems = [TodoItem()]
    @State private var todoItems = exampleTodos
//    @State private var focusedID: UUID?  // 跟踪当前焦点项
    @FocusState private var focusedField: UUID?  // SwiftUI 焦点管理
    
    
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
        .onAppear {
            focusedField = todoItems.first?.id
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
