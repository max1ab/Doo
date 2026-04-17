import SwiftUI

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
