////
////  new.swift
////  doo
////
////  Created by r00t on 2025/7/17.
////
//
//import SwiftUI
//
//struct TodoItem: Identifiable, Equatable {
//    let id = UUID()
//    var text: String
//    var isCompleted: Bool = false
//}
//
//struct TodoRowView: View {
//    @Binding var todo: TodoItem
//    var onCommit: () -> Void
//    var isFocused: Bool
//    var onToggleComplete: () -> Void
//    var onMoveUp: (() -> Void)?
//    var onMoveDown: (() -> Void)?
//    
//    var body: some View {
//        HStack {
//            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
//                .foregroundColor(todo.isCompleted ? .green : .gray)
//                .onTapGesture(perform: onToggleComplete)
//            
//            TextField("New todo", text: $todo.text, onCommit: onCommit)
//                .textFieldStyle(.plain)
//                .strikethrough(todo.isCompleted, color: .gray)
//                .foregroundColor(todo.isCompleted ? .gray : .primary)
//                .focusedValue(\.focusedTodoAction, FocusedTodoAction(
//                    moveUp: onMoveUp,
//                    moveDown: onMoveDown
//                ))
//        }
//    }
//}
//
//struct FocusedTodoAction {
//    let moveUp: (() -> Void)?
//    let moveDown: (() -> Void)?
//}
//
//struct ContentView: View {
//    @State private var todos: [TodoItem] = [TodoItem(text: "")]
//    @FocusState private var focusedField: UUID?
//    
//    var body: some View {
//        VStack {
//            Text("TODO List")
//                .font(.title)
//                .padding(.top)
//            
//            List {
//                ForEach(Array($todos.enumerated()), id: \.element.id) { index, $todo in
//                    TodoRowView(
//                        todo: $todo,
//                        onCommit: {
//                            // 只在当前项有内容时创建新项
//                            if !todo.text.trimmingCharacters(in: .whitespaces).isEmpty {
//                                addNewTodo(after: todo)
//                            }
//                        },
//                        isFocused: focusedField == todo.id,
//                        onToggleComplete: {
//                            todo.isCompleted.toggle()
//                        },
//                        onMoveUp: {
//                            moveFocus(to: index - 1)
//                        },
//                        onMoveDown: {
//                            moveFocus(to: index + 1)
//                        }
//                    )
//                    .focused($focusedField, equals: todo.id)
//                    .focusedSceneValue(\.focusedTodoAction, FocusedTodoAction(
//                        moveUp: {
//                            moveFocus(to: index - 1)
//                        },
//                        moveDown: {
//                            moveFocus(to: index + 1)
//                        }
//                    ))
//                    .listRowBackground(index % 2 == 0 ? Color(.systemBackground) : Color(.secondarySystemBackground))
//                }
//                .onDelete { indexSet in
//                    let deleteIndex = indexSet.first!
//                    todos.remove(atOffsets: indexSet)
//                    
//                    // 删除后聚焦到相邻项
//                    if todos.isEmpty {
//                        todos.append(TodoItem(text: ""))
//                        focusedField = todos.first?.id
//                    } else if deleteIndex < todos.count {
//                        focusedField = todos[deleteIndex].id
//                    } else {
//                        focusedField = todos.last?.id
//                    }
//                }
//            }
//            .listStyle(.plain)
//            .animation(.easeInOut, value: todos)
//            
//            HStack {
//                Text("\(todos.filter { !$0.text.isEmpty }.count) items")
//                    .font(.footnote)
//                    .foregroundColor(.secondary)
//                
//                Spacer()
//                
//                Button(action: clearEmptyItems) {
//                    Text("Clear Empty")
//                        .font(.footnote)
//                }
//            }
//            .padding()
//        }
//        .onAppear {
//            focusedField = todos.first?.id
//        }
//        .toolbar {
//            ToolbarItemGroup(placement: .keyboard) {
//                Button(action: moveFocusUp) {
//                    Image(systemName: "arrow.up")
//                }
//                .keyboardShortcut(.upArrow, modifiers: [])
//                
//                Button(action: moveFocusDown) {
//                    Image(systemName: "arrow.down")
//                }
//                .keyboardShortcut(.downArrow, modifiers: [])
//                
//                Spacer()
//                
//                Button(action: addItemBelow) {
//                    Image(systemName: "plus")
//                    Text("Add Below")
//                }
//                .keyboardShortcut(.return, modifiers: [])
//            }
//        }
//    }
//    
//    // 只在当前项有内容时添加新项
//    private func addNewTodo(after item: TodoItem) {
//        guard let index = todos.firstIndex(where: { $0.id == item.id }) else { return }
//        
//        let newTodo = TodoItem(text: "")
//        todos.insert(newTodo, at: index + 1)
//        
//        DispatchQueue.main.async {
//            focusedField = newTodo.id
//        }
//    }
//    
//    // 手动添加新项的按钮操作
//    private func addItemBelow() {
//        guard let focusedId = focusedField,
//              let index = todos.firstIndex(where: { $0.id == focusedId }) else { return }
//        
//        let newTodo = TodoItem(text: "")
//        todos.insert(newTodo, at: index + 1)
//        
//        DispatchQueue.main.async {
//            focusedField = newTodo.id
//        }
//    }
//    
//    private func moveFocus(to index: Int) {
//        guard todos.indices.contains(index) else { return }
//        focusedField = todos[index].id
//    }
//    
//    private func moveFocusUp() {
//        guard let currentFocused = focusedField,
//              let currentIndex = todos.firstIndex(where: { $0.id == currentFocused }) else { return }
//        moveFocus(to: currentIndex - 1)
//    }
//    
//    private func moveFocusDown() {
//        guard let currentFocused = focusedField,
//              let currentIndex = todos.firstIndex(where: { $0.id == currentFocused }) else { return }
//        moveFocus(to: currentIndex + 1)
//    }
//    
//    // 清理空项目
//    private func clearEmptyItems() {
//        todos = todos.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
//        if todos.isEmpty {
//            todos.append(TodoItem(text: ""))
//        }
//        focusedField = todos.first?.id
//    }
//}
//
//// 添加 FocusedValueKey 用于键盘导航
//private struct FocusedTodoActionKey: FocusedValueKey {
//    typealias Value = FocusedTodoAction
//}
//
//extension FocusedValues {
//    var focusedTodoAction: FocusedTodoAction? {
//        get { self[FocusedTodoActionKey.self] }
//        set { self[FocusedTodoActionKey.self] = newValue }
//    }
//}
//
//#Preview {
//    ContentView()
//}
