import Foundation
import AppKit

/**
 * 基础编辑对话框
 * 使用最简单的NSAlert创建一个编辑对话框
 */
class BasicEditDialog {
    static let shared = BasicEditDialog()
    
    private var recordManager = DayRecordManager()
    
    /**
     * 显示编辑对话框
     */
    func showEditDialog(for date: Date) {
        // 在主线程执行UI操作
        DispatchQueue.main.async {
            // 创建警告框
            let alert = NSAlert()
            alert.messageText = date.formatted("yyyy年MM月dd日") + " 记录"
            alert.informativeText = "请输入这一天的记录内容："
            
            // 添加按钮
            alert.addButton(withTitle: "保存")
            alert.addButton(withTitle: "取消")
            if self.recordManager.hasRecord(for: date) {
                alert.addButton(withTitle: "删除")
            }
            
            // 创建文本输入区域
            let textField = NSTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
            textField.isEditable = true
            textField.isSelectable = true
            textField.font = NSFont.systemFont(ofSize: 14)
            
            // 强制使用浅色主题颜色
            textField.textColor = NSColor.black
            textField.backgroundColor = NSColor.white
            textField.drawsBackground = true
            
            // 设置外观为浅色模式
            if #available(macOS 10.14, *) {
                textField.appearance = NSAppearance(named: .aqua)
            }
            
            // 如果有记录，加载内容
            if let record = self.recordManager.getRecord(for: date) {
                textField.string = record.content
            }
            
            // 创建滚动视图
            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
            scrollView.borderType = .bezelBorder
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.documentView = textField
            
            // 设置滚动视图的背景色为白色
            scrollView.backgroundColor = NSColor.white
            scrollView.drawsBackground = true
            
            // 如果可用，设置滚动视图的外观为浅色模式
            if #available(macOS 10.14, *) {
                scrollView.appearance = NSAppearance(named: .aqua)
            }
            
            // 设置视图
            alert.accessoryView = scrollView
            
            // 显示警告框并处理响应
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // 点击保存按钮
                let content = textField.string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty {
                    self.recordManager.saveRecord(for: date, content: content)
                    print("内容已保存: \(content)")
                    
                    // 通知刷新
                    self.notifyDataChanged()
                }
            } else if response == NSApplication.ModalResponse.alertThirdButtonReturn && self.recordManager.hasRecord(for: date) {
                // 点击删除按钮
                self.recordManager.deleteRecord(for: date)
                print("记录已删除")
                
                // 通知刷新
                self.notifyDataChanged()
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