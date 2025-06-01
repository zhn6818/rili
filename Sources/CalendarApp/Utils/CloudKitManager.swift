import Foundation
import CloudKit
import SwiftUI

/**
 * CloudKit管理器
 * 负责处理iCloud数据同步
 */
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    // CloudKit相关
    private var container: CKContainer?
    private var privateDatabase: CKDatabase?
    private let recordZone = CKRecordZone(zoneName: "CalendarRecords")
    
    // 发布的状态
    @Published var isSignedIn = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isAvailable = false
    
    // 记录类型
    private let recordType = "DayRecord"
    
    private init() {
        // 在开发环境下，我们可能无法使用CloudKit
        // 所以将isAvailable设为false
        isAvailable = false
        syncError = "需要通过签名应用使用iCloud"
        print("在开发环境中，CloudKit功能不可用。请使用sign_app.sh脚本签名应用后运行。")
    }
    
    /**
     * 设置CloudKit - 在签名的应用中调用此方法
     */
    func setupCloudKit() {
        // 仅在签名的应用中调用
        do {
            container = CKContainer(identifier: "iCloud.com.zhn6818.CalendarApp")
            privateDatabase = container?.privateCloudDatabase
            isAvailable = true
            
            // 检查iCloud状态
            checkiCloudStatus()
            
            // 创建自定义zone
            createZoneIfNeeded()
            
            print("CloudKit已成功初始化")
        } catch {
            print("CloudKit初始化失败: \(error)")
            isAvailable = false
            syncError = "CloudKit服务不可用"
        }
    }
    
    /**
     * 检查iCloud账户状态
     */
    func checkiCloudStatus() {
        guard let container = container else {
            isSignedIn = false
            syncError = "CloudKit未初始化"
            return
        }
        
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isSignedIn = true
                    self?.syncError = nil
                    print("iCloud账户可用")
                case .noAccount:
                    self?.isSignedIn = false
                    self?.syncError = "请登录iCloud账户"
                    print("未登录iCloud账户")
                case .restricted:
                    self?.isSignedIn = false
                    self?.syncError = "iCloud访问受限"
                case .couldNotDetermine:
                    self?.isSignedIn = false
                    self?.syncError = "无法确定iCloud状态"
                case .temporarilyUnavailable:
                    self?.isSignedIn = false
                    self?.syncError = "iCloud暂时不可用"
                @unknown default:
                    self?.isSignedIn = false
                }
            }
        }
    }
    
    /**
     * 创建自定义zone
     */
    private func createZoneIfNeeded() {
        guard let privateDatabase = privateDatabase else { return }
        
        let operation = CKModifyRecordZonesOperation(
            recordZonesToSave: [recordZone],
            recordZoneIDsToDelete: nil
        )
        
        operation.modifyRecordZonesResultBlock = { result in
            switch result {
            case .success:
                print("成功创建CloudKit Zone")
            case .failure(let error):
                print("创建Zone失败: \(error)")
            }
        }
        
        privateDatabase.add(operation)
    }
    
    /**
     * 保存记录到iCloud
     */
    func saveToCloud(_ dayRecord: DayRecord, completion: @escaping (Result<Void, Error>) -> Void) {
        guard isAvailable && isSignedIn else {
            completion(.failure(CloudKitError.notSignedIn))
            return
        }
        
        guard let privateDatabase = privateDatabase else {
            completion(.failure(CloudKitError.notAvailable))
            return
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        // 创建CKRecord
        let recordID = CKRecord.ID(
            recordName: dayRecord.id.uuidString,
            zoneID: recordZone.zoneID
        )
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        // 设置字段 - 将records数组序列化为JSON
        record["date"] = dayRecord.date as CKRecordValue
        do {
            let recordsData = try JSONEncoder().encode(dayRecord.records)
            record["recordsData"] = recordsData as CKRecordValue
        } catch {
            print("序列化records失败: \(error)")
            completion(.failure(error))
            return
        }
        record["createdAt"] = dayRecord.createdAt as CKRecordValue
        record["updatedAt"] = dayRecord.updatedAt as CKRecordValue
        
        // 保存到CloudKit
        privateDatabase.save(record) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isSyncing = false
                self?.lastSyncDate = Date()
                
                if let error = error {
                    self?.syncError = error.localizedDescription
                    completion(.failure(error))
                } else {
                    self?.syncError = nil
                    completion(.success(()))
                    print("记录已同步到iCloud")
                }
            }
        }
    }
    
    /**
     * 从iCloud获取所有记录
     */
    func fetchFromCloud(completion: @escaping (Result<[DayRecord], Error>) -> Void) {
        guard isAvailable && isSignedIn else {
            completion(.failure(CloudKitError.notSignedIn))
            return
        }
        
        guard let privateDatabase = privateDatabase else {
            completion(.failure(CloudKitError.notAvailable))
            return
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        let query = CKQuery(
            recordType: recordType,
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.zoneID = recordZone.zoneID
        
        var fetchedRecords: [DayRecord] = []
        
        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                if let dayRecord = self.recordToDayRecord(record) {
                    fetchedRecords.append(dayRecord)
                }
            case .failure(let error):
                print("获取记录失败: \(error)")
            }
        }
        
        operation.queryResultBlock = { [weak self] result in
            DispatchQueue.main.async {
                self?.isSyncing = false
                self?.lastSyncDate = Date()
                
                switch result {
                case .success:
                    self?.syncError = nil
                    completion(.success(fetchedRecords))
                    print("从iCloud获取了 \(fetchedRecords.count) 条记录")
                case .failure(let error):
                    self?.syncError = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
        
        privateDatabase.add(operation)
    }
    
    /**
     * 删除iCloud记录
     */
    func deleteFromCloud(_ recordID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard isAvailable && isSignedIn else {
            completion(.failure(CloudKitError.notSignedIn))
            return
        }
        
        guard let privateDatabase = privateDatabase else {
            completion(.failure(CloudKitError.notAvailable))
            return
        }
        
        let ckRecordID = CKRecord.ID(
            recordName: recordID,
            zoneID: recordZone.zoneID
        )
        
        privateDatabase.delete(withRecordID: ckRecordID) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    print("记录已从iCloud删除")
                }
            }
        }
    }
    
    /**
     * 将CKRecord转换为DayRecord
     */
    private func recordToDayRecord(_ record: CKRecord) -> DayRecord? {
        guard let date = record["date"] as? Date,
              let recordsData = record["recordsData"] as? Data,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        
        do {
            let records = try JSONDecoder().decode([RecordItem].self, from: recordsData)
            var dayRecord = DayRecord(date: date)
            dayRecord.id = id
            dayRecord.records = records
            dayRecord.createdAt = createdAt
            dayRecord.updatedAt = updatedAt
            return dayRecord
        } catch {
            print("反序列化records失败: \(error)")
            return nil
        }
    }
}

/**
 * CloudKit错误类型
 */
enum CloudKitError: LocalizedError {
    case notSignedIn
    case notAvailable
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "请先登录iCloud账户"
        case .notAvailable:
            return "CloudKit服务不可用"
        case .syncFailed(let message):
            return "同步失败: \(message)"
        }
    }
} 