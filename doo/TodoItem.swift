//import SwiftUI
//struct TodoItem: Identifiable {
//    let id = UUID()
//    var content: String
//    var isCompleted: Bool
//}
//struct ContentView: View {
//    @State private var items: [TodoItem] = [TodoItem(content: "", isCompleted: false)]
//    @FocusState private var focus: UUID?
//    
//    // 分区
//    private var uncompleted: [TodoItem] { items.filter{!$0.isCompleted} }
//    private var completed:   [TodoItem] { items.filter{$0.isCompleted} }
//    
//    var body: some View {
//        List {
//            ForEach(uncompleted) { Row(item: $0) }
//            ForEach(completed)   { Row(item: $0).grayscale(0.8) }
//        }
//        .listStyle(.plain)
//        .environment(\.defaultMinListRowHeight, 36)
////        .frame(width: 300, height: 400)
//        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
//            if !Calendar.current.isDateInToday(Date()) {
//                items = [TodoItem(content: "", isCompleted: false)]
//            }
//        }
//    }
//    // 每日清理
////    .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
////        if !Calendar.current.isDateInToday(Date()) {
////            items = [TodoItem(content: "", isCompleted: false)]
////        }
////    }
//    
//    // 行组件
//    @ViewBuilder
//    private func Row(item: TodoItem) -> some View {
//        HStack(spacing: 8) {
//            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
//                .foregroundStyle(item.isCompleted ? .secondary : .primary)
//                .onTapGesture { toggle(item) }
//            
//            if item.id == focus {
//                TextField("", text: bind(for: item), onCommit: { addIfNeeded() })
//                    .textFieldStyle(.plain)
//                    .focused($focus, equals: item.id)
//            } else {
//                Text(item.content)
//                    .strikethrough(item.isCompleted)
//                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
//                    .onTapGesture {
//                        if !item.isCompleted { focus = item.id }
//                    }
//            }
//        }
//        .swipeActions(edge: .leading) { Button(role: .destructive) { delete(item) } label:{ Image(systemName: "trash") } }
//        .contextMenu { Button("Delete", role: .destructive) { delete(item) } }
//    }
//    
//    // 绑定文本
//    private func bind(for item: TodoItem) -> Binding<String> {
//        .init(
//            get: { item.content },
//            set: { new in
//                if let idx = items.firstIndex(where: { $0.id == item.id }) {
//                    items[idx].content = new
//                }
//            }
//        )
//    }
//    
//    // 状态切换
//    private func toggle(_ item: TodoItem) {
//        withAnimation(.easeInOut(duration: 0.2)) {
//            if let idx = items.firstIndex(where: { $0.id == item.id }) {
//                items[idx].isCompleted.toggle()
//                if items[idx].isCompleted {
//                    items.move(fromOffsets: IndexSet(integer: idx), toOffset: items.count)
//                }
//            }
//        }
//    }
//    
//    // 删除
//    private func delete(_ item: TodoItem) {
//        withAnimation(.easeInOut(duration: 0.2)) {
//            items.removeAll { $0.id == item.id }
//            if items.isEmpty { items.append(TodoItem(content: "", isCompleted: false)) }
//        }
//    }
//    
//    // 回车自动新建
//    private func addIfNeeded() {
//        guard let last = items.last, !last.content.isEmpty else { return }
//        let new = TodoItem(content: "", isCompleted: false)
//        items.append(new)
//        focus = new.id
//    }
//}
//
//#Preview {
//    ContentView()
//}
