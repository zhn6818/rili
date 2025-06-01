import Foundation
import AppKit

/**
 * 系统编辑器管理器
 * 使用系统内置的文本编辑功能，确保100%可编辑
 */
class SystemEditorManager {
    static let shared = SystemEditorManager()
    
    private var recordManager = DayRecordManager()
    private var tempFiles = [URL: Date]()
    
    /**
     * 使用系统编辑器打开记录
     */
    func editRecord(for date: Date) {
        // 创建临时文件
        let tempURL = createTempFile(for: date)
        
        // 使用系统默认编辑器打开文件
        NSWorkspace.shared.open(tempURL)
        
        // 存储日期和文件的映射关系
        tempFiles[tempURL] = date
        
        // 设置文件监视器
        setupFileMonitor(for: tempURL, date: date)
    }
    
    /**
     * 关闭所有临时文件
     */
    func closeAll() {
        // 删除所有临时文件
        for (url, _) in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()
    }
    
    // MARK: - 私有方法
    
    private func createTempFile(for date: Date) -> URL {
        // 创建唯一的临时文件名
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let filename = "note_\(timestamp).txt"
        
        // 获取临时目录
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        // 获取记录内容
        var content = ""
        if let record = recordManager.getRecord(for: date) {
            content = record.content
        }
        
        // 写入文件
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("临时文件创建成功: \(fileURL.path)")
        } catch {
            print("创建临时文件失败: \(error.localizedDescription)")
        }
        
        return fileURL
    }
    
    private func setupFileMonitor(for url: URL, date: Date) {
        // 在后台线程中监视文件变化
        DispatchQueue.global(qos: .background).async {
            // 获取初始文件修改时间
            var lastModified = try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
            
            // 每秒检查一次文件是否被修改
            while self.tempFiles[url] != nil {
                // 获取当前修改时间
                let currentModified = try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
                
                // 如果文件被修改，则更新记录
                if let current = currentModified, let last = lastModified, current > last {
                    self.updateRecord(from: url, for: date)
                    lastModified = currentModified
                }
                
                // 暂停1秒
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }
    
    private func updateRecord(from url: URL, for date: Date) {
        do {
            // 读取文件内容
            let content = try String(contentsOf: url, encoding: .utf8)
            
            // 更新记录
            DispatchQueue.main.async {
                self.recordManager.saveRecord(for: date, content: content)
                print("记录已更新: \(content)")
                
                // 发送通知，通知日历视图刷新
                NotificationCenter.default.post(
                    name: NSNotification.Name("RecordUpdated"),
                    object: nil,
                    userInfo: ["date": date]
                )
            }
        } catch {
            print("读取文件内容失败: \(error.localizedDescription)")
        }
    }
} 