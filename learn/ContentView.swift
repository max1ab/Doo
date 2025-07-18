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
    TodoItem("睡觉",true),
    TodoItem("打豆豆"),
    TodoItem("完成代码和视频剪辑"),
    TodoItem("看书",true),
    TodoItem("",true)
]

struct TodoView: View {
    //@State private var todoItems = [TodoItem()]
    @State private var todoItems = exampleTodos
    @State private var focusedID: UUID?  // 跟踪当前焦点项
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
                    .onChange(of: item.content) {
                        if item.content.isEmpty && index != todoItems.count - 1 {
                            deleteItem(at: index)
                        }
                    }
                }
                .onMove(perform: move)
            }
        }
        .onAppear {
            focusedField = todoItems.first?.id
        }
        .onChange(of: focusedField) { newValue in
            focusedID = newValue
        }
        // 键盘事件监听
        .onKeyPress(.upArrow) { _ in
            moveFocusUp()
            return .handled
        }
        .onKeyPress(.downArrow) { _ in
            moveFocusDown()
            return .handled
        }
        .onKeyPress(.tab) { _ in
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
        guard todoItems[index].over else { return }
        
        //        var o: Int
        //        for o in
        var o = 0
        for i in todoItems.reversed() {
            if i.over {
                o += 1
            } else {
                break
            }
        }
        
        //        withAnimation {
        for i in index..<todoItems.count-1-o {
            withAnimation {
                todoItems.swapAt(i, i+1)
            }
        }
        //            todoItems.swapAt(0, 1)
        //            let doneItem = todoItems.remove(at: index)
        //            todoItems.append(doneItem)
        //        }
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
        guard let currentID = focusedID,
              let currentIndex = todoItems.firstIndex(where: { $0.id == currentID }),
              currentIndex > 0 else { return }
        
        focusedField = todoItems[currentIndex - 1].id
    }
    
    // 焦点下移
    private func moveFocusDown() {
        guard let currentID = focusedID else {
            focusedField = todoItems.first?.id
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
    
    @FocusedBinding var focusedID: UUID?
//    let isFocused: Bool
//    @FocusState private var isTextFieldFocused: Bool
    
    var onComplete: () -> Void
    var onEnter: ()-> Void
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
                        onComplete()
                        item.over = !item.over
                    }
                TextField("wtf", text: $item.content)
                    .autocorrectionDisabled(true)
                    .strikethrough(item.over)
                    .disabled(item.over)
                    .onSubmit(onEnter)
                    .padding(2)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        if isFocused {
                            DispatchQueue.main.async {
                                self.isTextFieldFocused = true
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    TodoView()
}
