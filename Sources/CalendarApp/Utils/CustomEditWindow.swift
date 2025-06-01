import Foundation
import AppKit

/**
 * 自定义编辑窗口
 * 创建一个完全自定义的编辑窗口，确保能够正确编辑内容
 */
class CustomEditWindow: NSObject {
    static let shared = CustomEditWindow()
    
    private var recordManager = DayRecordManager()
    private var window: NSWindow?
    private var textView: NSTextView?
    private var currentDate: Date?
    
    /**
     * 显示编辑窗口
     */
    func showEditor(for date: Date) {
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 保存当前日期
            self.currentDate = date
            
            // 如果已有窗口，先关闭
            self.closeWindow()
            
            // 创建窗口
            self.createWindow(for: date)
            
            // 显示窗口并设置焦点
            if let window = self.window, let textView = self.textView {
                // 先显示窗口
                window.center()
                window.makeKeyAndOrderFront(nil)
                
                // 激活应用程序 - 这很重要！
                NSApp.activate(ignoringOtherApps: true)
                
                // 设置窗口为模态面板级别
                window.level = .modalPanel
                
                // 确保窗口可以成为关键窗口
                window.makeKey()
                
                // 立即尝试设置焦点
                window.makeFirstResponder(textView)
                
                // 如果第一次失败，延迟再试一次
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // 再次确保应用激活
                    NSApp.activate(ignoringOtherApps: true)
                    
                    // 再次尝试设置焦点
                    if window.makeFirstResponder(textView) {
                        print("文本视图已获得焦点")
                        
                        // 将光标移到文本末尾
                        textView.setSelectedRange(NSRange(location: textView.string.count, length: 0))
                    } else {
                        print("无法设置文本视图为第一响应者")
                        
                        // 最后的尝试 - 直接让窗口成为key并让textView获得焦点
                        window.makeKeyAndOrderFront(nil)
                        textView.window?.makeFirstResponder(textView)
                    }
                }
            }
        }
    }
    
    /**
     * 关闭编辑窗口
     */
    func closeWindow() {
        window?.close()
        window = nil
        textView = nil
    }
    
    // MARK: - 私有方法
    
    private func createWindow(for date: Date) {
        // 获取屏幕尺寸
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowWidth: CGFloat = 500
        let windowHeight: CGFloat = 350
        let windowRect = NSRect(
            x: screenRect.midX - windowWidth/2,
            y: screenRect.midY - windowHeight/2,
            width: windowWidth,
            height: windowHeight
        )
        
        // 创建窗口
        let window = NSPanel(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // 格式化日期标题
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        window.title = formatter.string(from: date) + " 记录"
        
        window.isFloatingPanel = false  // 改为false，使其表现更像普通窗口
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        window.backgroundColor = NSColor.windowBackgroundColor
        window.delegate = self
        
        // 保存窗口引用
        self.window = window
        
        // 创建UI元素
        setupUI(in: window.contentView!, for: date)
    }
    
    private func setupUI(in view: NSView, for date: Date) {
        // 设置标题标签
        let titleLabel = NSTextField(labelWithString: "请输入这一天的记录内容：")
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.frame = NSRect(x: 20, y: view.frame.height - 50, width: view.frame.width - 40, height: 20)
        titleLabel.autoresizingMask = [.width, .minYMargin]
        view.addSubview(titleLabel)
        
        // 创建文本视图和滚动视图
        let scrollView = NSScrollView(frame: NSRect(
            x: 20,
            y: 60,
            width: view.frame.width - 40,
            height: view.frame.height - 120
        ))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        
        // 创建文本视图 - 使用更简单的初始化方式
        let textView = NSTextView()
        textView.frame = CGRect(x: 0, y: 0, width: scrollView.frame.width, height: scrollView.frame.height)
        textView.minSize = CGSize(width: 0, height: 0)
        textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = CGSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        // 设置文本视图属性
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // 如果有记录，加载内容
        if let record = recordManager.getRecord(for: date) {
            textView.string = record.content
        }
        
        scrollView.documentView = textView
        view.addSubview(scrollView)
        
        // 保存文本视图的引用
        self.textView = textView
        
        // 添加底部按钮
        let saveButton = NSButton(title: "保存", target: self, action: #selector(saveContent))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: view.frame.width - 100, y: 20, width: 80, height: 30)
        saveButton.autoresizingMask = [.minXMargin, .maxYMargin]
        saveButton.keyEquivalent = "\r" // Enter键
        view.addSubview(saveButton)
        
        let cancelButton = NSButton(title: "取消", target: self, action: #selector(cancelEdit))
        cancelButton.bezelStyle = .rounded
        cancelButton.frame = NSRect(x: view.frame.width - 190, y: 20, width: 80, height: 30)
        cancelButton.autoresizingMask = [.minXMargin, .maxYMargin]
        cancelButton.keyEquivalent = "\u{1b}" // ESC键
        view.addSubview(cancelButton)
        
        // 如果有记录，添加删除按钮
        if recordManager.hasRecord(for: date) {
            let deleteButton = NSButton(title: "删除", target: self, action: #selector(deleteRecord))
            deleteButton.bezelStyle = .rounded
            deleteButton.frame = NSRect(x: 20, y: 20, width: 80, height: 30)
            deleteButton.autoresizingMask = [.maxXMargin, .maxYMargin]
            view.addSubview(deleteButton)
        }
    }
    
    @objc private func saveContent() {
        guard let textView = self.textView, let date = currentDate else { return }
        
        let content = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty {
            recordManager.saveRecord(for: date, content: content)
            print("内容已保存: \(content)")
            
            // 通知刷新
            notifyDataChanged()
        }
        
        closeWindow()
    }
    
    @objc private func cancelEdit() {
        closeWindow()
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
        
        if let window = self.window {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    self.recordManager.deleteRecord(for: date)
                    print("记录已删除")
                    
                    // 通知刷新
                    self.notifyDataChanged()
                    self.closeWindow()
                }
            }
        }
    }
    
    /**
     * 通知数据变化
     */
    private func notifyDataChanged() {
        NotificationCenter.default.post(
            name: NSNotification.Name("RecordUpdated"),
            object: nil
        )
    }
}

// MARK: - 窗口代理
extension CustomEditWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // 当窗口关闭时，清理资源
        textView = nil
        window = nil
    }
} 