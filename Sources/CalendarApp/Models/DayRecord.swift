import Foundation
import SwiftUI

/**
 * 单条记录数据模型
 * 表示某一天的一条记录
 */
struct RecordItem: Identifiable, Codable {
    var id = UUID()
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    init(content: String = "") {
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
 * 日记录数据模型
 * 用于存储每日的多条记录
 */
struct DayRecord: Identifiable, Codable {
    var id = UUID()
    let date: Date
    var records: [RecordItem]
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, date, records, createdAt, updatedAt
    }
    
    init(date: Date) {
        self.date = date
        self.records = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 添加记录
    mutating func addRecord(_ content: String) {
        let newRecord = RecordItem(content: content)
        records.append(newRecord)
        updatedAt = Date()
    }
    
    // 更新记录
    mutating func updateRecord(id: UUID, content: String) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index].updateContent(content)
            updatedAt = Date()
        }
    }
    
    // 删除记录
    mutating func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        updatedAt = Date()
    }
    
    // 检查是否有记录
    var hasRecords: Bool {
        return !records.isEmpty && records.contains { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

/**
 * 日记录管理器
 * 负责管理所有日记录的增删改查操作，支持本地存储和iCloud同步
 */
class DayRecordManager: ObservableObject {
    @Published var dayRecords: [String: DayRecord] = [:]
    
    private let fileManager = FileManager.default
    private let cloudKitManager = CloudKitManager.shared
    @AppStorage("enableiCloudSync") private var enableiCloudSync = false
    
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
        
        // 监听iCloud同步通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("EnableiCloudSync"),
            object: nil,
            queue: .main
        ) { _ in
            if self.enableiCloudSync && self.cloudKitManager.isSignedIn {
                self.syncWithiCloud()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ManualiCloudSync"),
            object: nil,
            queue: .main
        ) { _ in
            if self.enableiCloudSync && self.cloudKitManager.isSignedIn {
                self.syncWithiCloud()
            }
        }
        
        // 如果已启用并登录iCloud，同步数据
        if enableiCloudSync && cloudKitManager.isSignedIn {
            syncWithiCloud()
        }
    }
    
    // MARK: - 日期记录管理
    
    /**
     * 获取指定日期的所有记录
     */
    func getDayRecord(for date: Date) -> DayRecord? {
        let key = dateKey(for: date)
        return dayRecords[key]
    }
    
    /**
     * 获取指定日期的记录列表
     */
    func getRecords(for date: Date) -> [RecordItem] {
        let key = dateKey(for: date)
        return dayRecords[key]?.records ?? []
    }
    
    /**
     * 添加记录到指定日期
     */
    func addRecord(to date: Date, content: String) {
        let key = dateKey(for: date)
        
        if var dayRecord = dayRecords[key] {
            dayRecord.addRecord(content)
            dayRecords[key] = dayRecord
        } else {
            var newDayRecord = DayRecord(date: date)
            newDayRecord.addRecord(content)
            dayRecords[key] = newDayRecord
        }
        
        saveRecords()
        
        // 同步到iCloud
        if enableiCloudSync, let dayRecord = dayRecords[key] {
            syncToiCloud(dayRecord)
        }
    }
    
    /**
     * 更新指定记录
     */
    func updateRecord(date: Date, recordId: UUID, content: String) {
        let key = dateKey(for: date)
        
        if var dayRecord = dayRecords[key] {
            dayRecord.updateRecord(id: recordId, content: content)
            dayRecords[key] = dayRecord
            
            saveRecords()
            
            // 同步到iCloud
            if enableiCloudSync {
                syncToiCloud(dayRecord)
            }
        }
    }
    
    /**
     * 删除指定记录
     */
    func deleteRecord(date: Date, recordId: UUID) {
        let key = dateKey(for: date)
        
        if var dayRecord = dayRecords[key] {
            dayRecord.deleteRecord(id: recordId)
            
            // 如果没有记录了，删除整个日期记录
            if dayRecord.records.isEmpty {
                dayRecords.removeValue(forKey: key)
            } else {
                dayRecords[key] = dayRecord
            }
            
            saveRecords()
            
            // 从iCloud删除
            if enableiCloudSync {
                if dayRecords[key] != nil {
                    syncToiCloud(dayRecords[key]!)
                } else {
                    // 删除整个日期记录
                    cloudKitManager.deleteFromCloud(dayRecord.id.uuidString) { result in
                        switch result {
                        case .success:
                            print("从iCloud删除成功")
                        case .failure(let error):
                            print("从iCloud删除失败: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    /**
     * 检查指定日期是否有记录
     */
    func hasRecord(for date: Date) -> Bool {
        let key = dateKey(for: date)
        return dayRecords[key]?.hasRecords ?? false
    }
    
    /**
     * 获取指定日期的记录数量
     */
    func recordCount(for date: Date) -> Int {
        let key = dateKey(for: date)
        return dayRecords[key]?.records.count ?? 0
    }
    
    // MARK: - 兼容性方法（为了不破坏现有代码）
    
    /**
     * 获取指定日期的记录（兼容旧接口）
     */
    func getRecord(for date: Date) -> DayRecord? {
        return getDayRecord(for: date)
    }
    
    /**
     * 保存或更新指定日期的记录（兼容旧接口）
     */
    func saveRecord(for date: Date, content: String) {
        addRecord(to: date, content: content)
    }
    
    /**
     * 删除指定日期的记录（兼容旧接口）
     */
    func deleteRecord(for date: Date) {
        let key = dateKey(for: date)
        if let dayRecord = dayRecords[key] {
            dayRecords.removeValue(forKey: key)
            saveRecords()
            
            // 从iCloud删除
            if enableiCloudSync {
                cloudKitManager.deleteFromCloud(dayRecord.id.uuidString) { result in
                    switch result {
                    case .success:
                        print("从iCloud删除成功")
                    case .failure(let error):
                        print("从iCloud删除失败: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - iCloud同步
    
    /**
     * 同步单条记录到iCloud
     */
    private func syncToiCloud(_ dayRecord: DayRecord) {
        // 这里需要修改CloudKit实现以支持新的数据结构
        // 暂时保持原有逻辑
        print("同步日期记录到iCloud: \(dayRecord.date)")
    }
    
    /**
     * 从iCloud同步所有记录
     */
    func syncWithiCloud() {
        print("从iCloud同步记录")
        // TODO: 实现CloudKit同步逻辑
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
            self.dayRecords = decodedRecords
            print("成功加载 \(decodedRecords.count) 个日期的记录")
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
            let data = try JSONEncoder().encode(dayRecords)
            try data.write(to: fileURL)
            print("成功保存 \(dayRecords.count) 个日期的记录到: \(fileURL.path)")
        } catch {
            print("保存记录失败: \(error)")
        }
    }
} 