import Foundation
import AppKit
import SwiftUI

/**
 * 原生编辑器控制器
 * 使用AppKit原生组件来确保编辑功能正常工作
 */
class NativeEditorController: NSObject {
    
    static let shared = NativeEditorController()
    
    private var editorWindows = [Date: NSWindow]()
    private var recordManager = DayRecordManager()
    
    /**
     * 打开编辑器窗口
     */
    func openEditor(for date: Date) {
        // 如果已经有窗口打开，则关闭它
        closeEditorIfNeeded(for: date)
        
        // 创建新窗口
        let window = createEditorWindow(for: date)
        editorWindows[date] = window
        
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /**
     * 关闭编辑器窗口
     */
    func closeEditor(for date: Date) {
        closeEditorIfNeeded(for: date)
    }
    
    /**
     * 关闭所有编辑器窗口
     */
    func closeAllEditors() {
        for (date, _) in editorWindows {
            closeEditorIfNeeded(for: date)
        }
    }
    
    // MARK: - 私有方法
    
    private func closeEditorIfNeeded(for date: Date) {
        if let window = editorWindows[date] {
            window.close()
            editorWindows.removeValue(forKey: date)
        }
    }
    
    private func createEditorWindow(for date: Date) -> NSWindow {
        // 计算窗口位置（居中）
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 300
        let windowRect = NSRect(
            x: screenRect.midX - windowWidth/2,
            y: screenRect.midY - windowHeight/2,
            width: windowWidth,
            height: windowHeight
        )
        
        // 创建窗口
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // 配置窗口
        window.title = date.formatted("yyyy年M月d日") + " 记录"
        window.isReleasedWhenClosed = false
        window.center()
        
        // 创建视图控制器
        let editorViewController = EditorViewController(date: date, recordManager: recordManager)
        window.contentViewController = editorViewController
        
        // 设置关闭回调
        window.delegate = self
        
        return window
    }
}

// MARK: - 窗口代理
extension NativeEditorController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // 找到对应的日期并移除
        for (date, storedWindow) in editorWindows where storedWindow == window {
            editorWindows.removeValue(forKey: date)
            break
        }
    }
}

// MARK: - 编辑器视图控制器
class EditorViewController: NSViewController {
    
    private let date: Date
    private let recordManager: DayRecordManager
    
    private var textView: NSTextView!
    private var saveButton: NSButton!
    private var cancelButton: NSButton!
    private var deleteButton: NSButton!
    private var countLabel: NSTextField!
    
    init(date: Date, recordManager: DayRecordManager) {
        self.date = date
        self.recordManager = recordManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView()
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadContent()
    }
    
    // MARK: - UI设置
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // 创建滚动视图和文本视图
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: view.bounds.width - 40, height: view.bounds.height - 100))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        
        textView = NSTextView(frame: scrollView.bounds)
        textView.autoresizingMask = [.width, .height]
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.delegate = self
        
        scrollView.documentView = textView
        view.addSubview(scrollView)
        
        // 字数标签
        countLabel = NSTextField(labelWithString: "0 字")
        countLabel.frame = NSRect(x: 20, y: 20, width: 100, height: 20)
        countLabel.font = NSFont.systemFont(ofSize: 12)
        countLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(countLabel)
        
        // 保存按钮
        saveButton = NSButton(title: "保存", target: self, action: #selector(saveContent))
        saveButton.frame = NSRect(x: view.bounds.width - 90, y: 20, width: 70, height: 24)
        saveButton.autoresizingMask = [.minXMargin]
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Enter键
        view.addSubview(saveButton)
        
        // 取消按钮
        cancelButton = NSButton(title: "取消", target: self, action: #selector(cancel))
        cancelButton.frame = NSRect(x: view.bounds.width - 170, y: 20, width: 70, height: 24)
        cancelButton.autoresizingMask = [.minXMargin]
        cancelButton.bezelStyle = .rounded
        view.addSubview(cancelButton)
        
        // 删除按钮
        if recordManager.hasRecord(for: date) {
            deleteButton = NSButton(title: "删除", target: self, action: #selector(deleteRecord))
            deleteButton.frame = NSRect(x: 130, y: 20, width: 70, height: 24)
            deleteButton.bezelStyle = .rounded
            deleteButton.contentTintColor = NSColor.systemRed
            view.addSubview(deleteButton)
        }
    }
    
    // MARK: - 内容管理
    
    private func loadContent() {
        if let record = recordManager.getRecord(for: date) {
            textView.string = record.content
        } else {
            textView.string = ""
        }
        updateCharCount()
    }
    
    private func updateCharCount() {
        countLabel.stringValue = "\(textView.string.count) 字"
    }
    
    @objc private func saveContent() {
        let content = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty {
            recordManager.saveRecord(for: date, content: content)
        }
        closeWindow()
    }
    
    @objc private func cancel() {
        closeWindow()
    }
    
    @objc private func deleteRecord() {
        let alert = NSAlert()
        alert.messageText = "确认删除"
        alert.informativeText = "确定要删除这条记录吗？此操作不可撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        
        alert.beginSheetModal(for: view.window!) { response in
            if response == .alertFirstButtonReturn {
                self.recordManager.deleteRecord(for: self.date)
                self.closeWindow()
            }
        }
    }
    
    private func closeWindow() {
        view.window?.close()
    }
}

// MARK: - 文本视图代理
extension EditorViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        updateCharCount()
    }
} 