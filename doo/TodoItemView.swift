import SwiftUI

struct TodoItemView: View {
    @Binding var item: TodoItem
    @State private var hoverDate = Date()
    @FocusState private var isTextFieldFocused: Bool

    var onComplete: () -> Void
    var onEnter: () -> Void

    var body: some View {
        HStack {
            Image(systemName: item.over ? "checkmark.circle.fill" : (item.isRunning ? "play.circle.fill" : "circle"))
                .font(.system(size: 16))
                .foregroundStyle(item.isRunning ? Color.accentColor : (item.over ? .secondary : .primary))
                .frame(width: 22, height: 22)
                .overlay {
                    TaskCircleMouseHandler(
                        onClick: completeItem,
                        onRightClick: { item.toggleExecution() }
                    )
                    .accessibilityHidden(true)
                }
                .accessibilityLabel(item.over ? "已完成" : (item.isRunning ? "正在执行" : "空闲"))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { completeItem() }
                .accessibilityAction(named: "开始或暂停") { item.toggleExecution() }
                .help("总执行时间：\(item.formattedElapsedTime(at: hoverDate))\n" + (item.over ? "左键恢复任务" : "左键完成，右键开始或暂停"))
            if item.over {
                Text(item.content)
                    .strikethrough(true, color: .gray)
                    .foregroundStyle(.gray)
                    .padding(2)
            } else {
                TextField("wtf", text: $item.content)
                    .autocorrectionDisabled(true)
                    .strikethrough(item.over)
                    .disabled(item.over)
                    .onSubmit(onEnter)
                    .padding(2)
                    .focused($isTextFieldFocused)
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovered in
            if isHovered { hoverDate = Date() }
        }
        .help("总执行时间：\(item.formattedElapsedTime(at: hoverDate))")
    }

    private func completeItem() {
        item.toggleCompletion()
        if item.over { onComplete() }
    }
}
