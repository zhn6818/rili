import SwiftUI
import AppKit

/**
 * 日期编辑对话框
 * 简洁的弹出式窗口，用于编辑指定日期的记录
 */
struct DayEditView: View {
    let date: Date
    let recordManager: DayRecordManager
    let onClose: () -> Void
    
    @State private var content: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // 固定的窗口尺寸
    private let windowWidth: CGFloat = 400
    private let windowHeight: CGFloat = 300
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                // 日期标题
                Text(date.formatted("yyyy年M月d日"))
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // 关闭按钮
                Button(action: {
                    saveAndClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.blue)
            
            // 编辑区域
            VStack(spacing: 16) {
                // 简单的文本编辑区
                ZStack(alignment: .topLeading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 2)
                    
                    // 简单的文本编辑器，没有花哨的配置
                    if #available(macOS 13.0, *) {
                        TextEditor(text: $content)
                            .scrollContentBackground(.hidden)
                            .focused($isTextFieldFocused)
                            .font(.body)
                            .padding(8)
                            .background(Color.clear)
                    } else {
                        NSViewWrapper(text: $content)
                            .padding(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 底部按钮
                HStack {
                    // 删除按钮
                    if recordManager.hasRecord(for: date) {
                        Button("删除") {
                            recordManager.deleteRecord(for: date)
                            onClose()
                        }
                        .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    // 当前字数
                    Text("\(content.count) 字")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 取消和保存按钮
                    HStack(spacing: 12) {
                        Button("取消") {
                            onClose()
                        }
                        .foregroundColor(.primary)
                        
                        Button("保存") {
                            saveAndClose()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(4)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .frame(width: windowWidth, height: windowHeight)
        .cornerRadius(8)
        .shadow(radius: 10)
        .onAppear {
            loadContent()
            // 自动聚焦文本框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func loadContent() {
        if let record = recordManager.getRecord(for: date) {
            content = record.content
            print("已加载记录内容: \(content)")
        } else {
            content = ""
            print("该日期无记录，显示空白编辑框")
        }
    }
    
    private func saveAndClose() {
        print("保存内容: \(content)")
        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            recordManager.saveRecord(for: date, content: content)
            print("内容已保存")
        }
        onClose()
    }
}

// MARK: - NSTextView包装器
struct NSViewWrapper: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.string = text
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground = true
        textView.isRichText = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSViewWrapper
        
        init(_ parent: NSViewWrapper) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

// MARK: - 预览
struct DayEditView_Previews: PreviewProvider {
    static var previews: some View {
        DayEditView(
            date: Date(),
            recordManager: DayRecordManager(),
            onClose: {}
        )
    }
} 