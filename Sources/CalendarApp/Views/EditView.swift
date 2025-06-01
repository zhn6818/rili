import SwiftUI

/**
 * 编辑视图
 * 使用SwiftUI创建的简单编辑界面
 */
struct EditView: View {
    let date: Date
    @Binding var isPresented: Bool
    @State private var content: String = ""
    @StateObject private var recordManager = DayRecordManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(formattedDate)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("关闭") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            // 编辑区域
            TextEditor(text: $content)
                .font(.system(size: 14))
                .padding(8)
                .onAppear {
                    // 加载已有内容
                    if let record = recordManager.getRecord(for: date) {
                        content = record.content
                    }
                }
            
            // 按钮栏
            HStack {
                if recordManager.hasRecord(for: date) {
                    Button("删除") {
                        deleteRecord()
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("保存") {
                    saveContent()
                }
                .keyboardShortcut(.return, modifiers: .command) // 使用Cmd+Return避免与TextEditor冲突
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 500, height: 400)
        .background(Color(NSColor.textBackgroundColor))
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    private func saveContent() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedContent.isEmpty {
            recordManager.saveRecord(for: date, content: trimmedContent)
            print("内容已保存: \(trimmedContent)")
            
            // 通知刷新
            NotificationCenter.default.post(
                name: NSNotification.Name("RecordUpdated"),
                object: nil
            )
        }
        isPresented = false
    }
    
    private func deleteRecord() {
        recordManager.deleteRecord(for: date)
        print("记录已删除")
        
        // 通知刷新
        NotificationCenter.default.post(
            name: NSNotification.Name("RecordUpdated"),
            object: nil
        )
        isPresented = false
    }
} 