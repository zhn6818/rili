import SwiftUI
import AppKit

/**
 * 编辑视图
 * 管理指定日期的多条记录
 */
struct EditView: View {
    let date: Date
    @Binding var isPresented: Bool
    @StateObject private var recordManager = DayRecordManager()
    
    @State private var records: [RecordItem] = []
    @State private var showingAddRecord = false
    @State private var editingRecord: RecordItem?
    @State private var newRecordContent = ""
    @State private var editingContent = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            
            // 记录列表
            if records.isEmpty {
                emptyStateView
            } else {
                recordsListView
            }
            
            // 底部按钮栏
            bottomButtonsView
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.textBackgroundColor))
        .onAppear {
            loadRecords()
        }
        .sheet(isPresented: $showingAddRecord) {
            RecordEditSheet(
                title: "添加新记录",
                content: $newRecordContent,
                isPresented: $showingAddRecord,
                onSave: {
                    addNewRecord()
                }
            )
        }
        .sheet(item: $editingRecord) { record in
            RecordEditSheet(
                title: "编辑记录",
                content: $editingContent,
                isPresented: .constant(true),
                onSave: {
                    updateRecord(record)
                },
                onDismiss: {
                    editingRecord = nil
                }
            )
        }
    }
    
    // 标题栏
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(records.count) 条记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("关闭") {
                isPresented = false
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("这一天还没有记录")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Button(action: {
                newRecordContent = ""
                showingAddRecord = true
            }) {
                Text("添加第一条记录")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 记录列表视图
    private var recordsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(records) { record in
                    RecordItemView(
                        record: record,
                        onEdit: {
                            editingContent = record.content
                            editingRecord = record
                        },
                        onDelete: {
                            deleteRecord(record)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // 底部按钮栏
    private var bottomButtonsView: some View {
        HStack {
            Button(action: {
                newRecordContent = ""
                showingAddRecord = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("添加记录")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut("n", modifiers: .command)
            
            Spacer()
            
            if !records.isEmpty {
                Button("清空所有") {
                    clearAllRecords()
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - 数据操作
    
    private func loadRecords() {
        records = recordManager.getRecords(for: date)
    }
    
    private func addNewRecord() {
        let trimmedContent = newRecordContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedContent.isEmpty {
            recordManager.addRecord(to: date, content: trimmedContent)
            loadRecords()
            
            // 通知刷新
            NotificationCenter.default.post(
                name: NSNotification.Name("RecordUpdated"),
                object: nil
            )
        }
        newRecordContent = ""
    }
    
    private func updateRecord(_ record: RecordItem) {
        let trimmedContent = editingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedContent.isEmpty {
            recordManager.updateRecord(date: date, recordId: record.id, content: trimmedContent)
            loadRecords()
            
            // 通知刷新
            NotificationCenter.default.post(
                name: NSNotification.Name("RecordUpdated"),
                object: nil
            )
        }
        editingRecord = nil
        editingContent = ""
    }
    
    private func deleteRecord(_ record: RecordItem) {
        recordManager.deleteRecord(date: date, recordId: record.id)
        loadRecords()
        
        // 通知刷新
        NotificationCenter.default.post(
            name: NSNotification.Name("RecordUpdated"),
            object: nil
        )
    }
    
    private func clearAllRecords() {
        recordManager.deleteRecord(for: date)
        loadRecords()
        
        // 通知刷新
        NotificationCenter.default.post(
            name: NSNotification.Name("RecordUpdated"),
            object: nil
        )
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}

/**
 * 单条记录显示视图
 */
struct RecordItemView: View {
    let record: RecordItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 记录内容
            Text(record.content)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .textSelection(.enabled)
            
            // 底部信息栏
            HStack {
                Text("创建: \(formatTime(record.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if record.updatedAt != record.createdAt {
                    Text("• 更新: \(formatTime(record.updatedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 操作按钮
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("编辑")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("删除")
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

/**
 * 记录编辑弹窗
 */
struct RecordEditSheet: View {
    let title: String
    @Binding var content: String
    @Binding var isPresented: Bool
    let onSave: () -> Void
    let onDismiss: (() -> Void)?
    
    init(title: String, content: Binding<String>, isPresented: Binding<Bool>, onSave: @escaping () -> Void, onDismiss: (() -> Void)? = nil) {
        self.title = title
        self._content = content
        self._isPresented = isPresented
        self.onSave = onSave
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            // 编辑区域
            ZStack {
                TextEditor(text: $content)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                
                // 水印提示
                if content.isEmpty {
                    VStack {
                        HStack {
                            Text("写点什么...")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.leading, 16)
                                .padding(.top, 16)
                            Spacer()
                        }
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
            }
            
            // 底部按钮
            HStack {
                Text("\(content.count) 字")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("保存") {
                    onSave()
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 400, height: 300)
        .background(Color(NSColor.textBackgroundColor))
    }
    
    private func dismiss() {
        isPresented = false
        onDismiss?()
    }
} 