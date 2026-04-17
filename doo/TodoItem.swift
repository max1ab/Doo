import Foundation

struct TodoItem: Identifiable {
    let id = UUID()
    var over = false
    var content = ""

    init(_ content: String = "", _ over: Bool = false) {
        self.content = content
        self.over = over
    }
}
