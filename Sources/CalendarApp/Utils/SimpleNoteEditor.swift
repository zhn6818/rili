import Foundation
import AppKit

/**
 * 简单笔记编辑器
 * 使用最基本的AppKit组件确保编辑功能可用
 */
class SimpleNoteEditor: NSObject {
    static let shared = SimpleNoteEditor()
    
    private var recordManager = DayRecordManager()
    private var currentDate: Date?
    private var panel: NSPanel?
    private var textView: NSTextView?
    
    /**
     * 显示编辑器
     */
    func showEditor(for date: Date) {
        // 如果已有窗口，先关闭
        closeEditor()
        
        // 保存当前日期
        currentDate = date
        
        // 创建面板
        createPanel(for: date)
        
        // 加载内容
        loadContent(for: date)
        
        // 显示窗口
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /**
     * 关闭编辑器
     */
    func closeEditor() {
        panel?.close()
        panel = nil
        textView = nil
    }
    
    // MARK: - 私有方法
    
    private func createPanel(for date: Date) {
        // 创建面板
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let panelWidth: CGFloat = 400
        let panelHeight: CGFloat = 300
        let panelRect = NSRect(
            x: screenRect.midX - panelWidth/2,
            y: screenRect.midY - panelHeight/2,
            width: panelWidth,
            height: panelHeight
        )
        
        let panel = NSPanel(
            contentRect: panelRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = date.formatted("yyyy年M月d日") + " 记录"
        panel.isFloatingPanel = true
        panel.contentView = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        panel.center()
        
        // 设置面板的委托
        panel.delegate = self
        
        // 保存面板引用
        self.panel = panel
        
        // 创建UI元素
        setupUI(in: panel.contentView!, for: date)
    }
    
    private func setupUI(in view: NSView, for date: Date) {
        // 创建文本视图和滚动视图
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: view.frame.width - 40, height: view.frame.height - 90))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        
        let textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.textColor
        textView.drawsBackground = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        
        scrollView.documentView = textView
        view.addSubview(scrollView)
        
        // 保存文本视图的引用
        self.textView = textView
        
        // 添加底部按钮
        let saveButton = NSButton(title: "保存", target: self, action: #selector(saveContent))
        saveButton.frame = NSRect(x: view.frame.width - 90, y: 20, width: 70, height: 24)
        saveButton.autoresizingMask = [.minXMargin]
        saveButton.bezelStyle = .rounded
        view.addSubview(saveButton)
        
        let cancelButton = NSButton(title: "取消", target: self, action: #selector(cancelEdit))
        cancelButton.frame = NSRect(x: view.frame.width - 170, y: 20, width: 70, height: 24)
        cancelButton.autoresizingMask = [.minXMargin]
        cancelButton.bezelStyle = .rounded
        view.addSubview(cancelButton)
        
        // 如果有记录，添加删除按钮
        if recordManager.hasRecord(for: date) {
            let deleteButton = NSButton(title: "删除", target: self, action: #selector(deleteRecord))
            deleteButton.frame = NSRect(x: 20, y: 20, width: 70, height: 24)
            deleteButton.bezelStyle = .rounded
            view.addSubview(deleteButton)
        }
    }
    
    private func loadContent(for date: Date) {
        guard let textView = self.textView else { return }
        
        if let dayRecord = recordManager.getRecord(for: date) {
            // 将所有记录的内容合并显示
            let allContent = dayRecord.records.map { $0.content }.joined(separator: "\n\n")
            textView.string = allContent
        } else {
            textView.string = ""
        }
    }
    
    @objc private func saveContent() {
        guard let textView = self.textView, let date = currentDate else { return }
        
        let content = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty {
            recordManager.saveRecord(for: date, content: content)
            print("内容已保存: \(content)")
            
            // 发送通知，通知日历视图刷新
            NotificationCenter.default.post(
                name: NSNotification.Name("RecordUpdated"),
                object: nil,
                userInfo: ["date": date]
            )
        }
        
        closeEditor()
    }
    
    @objc private func cancelEdit() {
        closeEditor()
    }
    
    @objc private func deleteRecord() {
        guard let date = currentDate else { return }
        
        // 显示确认对话框
        let alert = NSAlert()
        alert.messageText = "确认删除"
        alert.informativeText = "确定要删除这条记录吗？此操作不可撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        
        if let panel = self.panel {
            alert.beginSheetModal(for: panel) { response in
                if response == .alertFirstButtonReturn {
                    self.recordManager.deleteRecord(for: date)
                    
                    // 发送通知，通知日历视图刷新
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RecordUpdated"),
                        object: nil,
                        userInfo: ["date": date]
                    )
                    
                    self.closeEditor()
                }
            }
        }
    }
}

// MARK: - 窗口代理
extension SimpleNoteEditor: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // 当窗口关闭时，清理资源
        textView = nil
        panel = nil
    }
} 