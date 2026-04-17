import Foundation

struct TodoItem: Identifiable, Equatable {
    let id = UUID()
    var over = false
    var content = ""

    init(_ content: String = "", _ over: Bool = false) {
        self.content = content
        self.over = over
    }
}
