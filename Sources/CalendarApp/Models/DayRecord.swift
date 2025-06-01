import Foundation
import SwiftUI

/**
 * 日记录数据模型
 * 用于存储每日的记录内容和相关信息
 */
struct DayRecord: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, date, content, createdAt, updatedAt
    }
    
    init(date: Date, content: String = "") {
        self.date = date
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func updateContent(_ newContent: String) {
        self.content = newContent
        self.updatedAt = Date()
    }
}

/**
 * 日记录管理器
 * 负责管理所有日记录的增删改查操作
 */
class DayRecordManager: ObservableObject {
    @Published var records: [String: DayRecord] = [:]
    
    private let fileManager = FileManager.default
    private var dataDirectory: URL? {
        // 获取项目根目录下的tmp文件夹
        let currentDirectory = fileManager.currentDirectoryPath
        let tmpURL = URL(fileURLWithPath: currentDirectory).appendingPathComponent("tmp")
        
        // 如果文件夹不存在，创建它
        if !fileManager.fileExists(atPath: tmpURL.path) {
            do {
                try fileManager.createDirectory(at: tmpURL, withIntermediateDirectories: true, attributes: nil)
                print("创建tmp文件夹: \(tmpURL.path)")
            } catch {
                print("创建tmp文件夹失败: \(error)")
                return nil
            }
        }
        
        return tmpURL
    }
    
    private var recordsFileURL: URL? {
        return dataDirectory?.appendingPathComponent("dayRecords.json")
    }
    
    init() {
        loadRecords()
        
        // 监听记录更新通知，重新加载数据
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RecordUpdated"),
            object: nil,
            queue: .main
        ) { _ in
            self.loadRecords()
        }
    }
    
    /**
     * 获取指定日期的记录
     */
    func getRecord(for date: Date) -> DayRecord? {
        let key = dateKey(for: date)
        return records[key]
    }
    
    /**
     * 保存或更新指定日期的记录
     */
    func saveRecord(for date: Date, content: String) {
        let key = dateKey(for: date)
        
        if var existingRecord = records[key] {
            existingRecord.updateContent(content)
            records[key] = existingRecord
        } else {
            let newRecord = DayRecord(date: date, content: content)
            records[key] = newRecord
        }
        
        saveRecords()
    }
    
    /**
     * 删除指定日期的记录
     */
    func deleteRecord(for date: Date) {
        let key = dateKey(for: date)
        records.removeValue(forKey: key)
        saveRecords()
    }
    
    /**
     * 检查指定日期是否有记录
     */
    func hasRecord(for date: Date) -> Bool {
        let key = dateKey(for: date)
        return records[key] != nil && !records[key]!.content.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func loadRecords() {
        guard let fileURL = recordsFileURL else {
            print("无法获取记录文件路径")
            return
        }
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("记录文件不存在: \(fileURL.path)")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decodedRecords = try JSONDecoder().decode([String: DayRecord].self, from: data)
            self.records = decodedRecords
            print("成功加载 \(decodedRecords.count) 条记录")
        } catch {
            print("加载记录失败: \(error)")
        }
    }
    
    private func saveRecords() {
        guard let fileURL = recordsFileURL else {
            print("无法获取记录文件路径")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL)
            print("成功保存 \(records.count) 条记录到: \(fileURL.path)")
        } catch {
            print("保存记录失败: \(error)")
        }
    }
} 