import SwiftUI

/**
 * 设置视图
 * 允许用户配置应用设置，包括iCloud同步
 */
struct SettingsView: View {
    @Binding var isPresented: Bool
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @AppStorage("enableiCloudSync") private var enableiCloudSync = false
    @AppStorage("autoSync") private var autoSync = true
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("设置")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("完成") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            // 设置内容
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // iCloud同步设置
                    GroupBox(label: Label("iCloud同步", systemImage: "icloud")) {
                        VStack(alignment: .leading, spacing: 12) {
                            // iCloud状态
                            HStack {
                                if !cloudKitManager.isAvailable {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("iCloud服务暂不可用（需要开发者账号配置）")
                                } else if cloudKitManager.isSignedIn {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("已登录iCloud")
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text(cloudKitManager.syncError ?? "未登录iCloud")
                                }
                                Spacer()
                            }
                            .font(.system(size: 14))
                            
                            Divider()
                            
                            // 启用iCloud同步
                            Toggle("启用iCloud同步", isOn: $enableiCloudSync)
                                .disabled(!cloudKitManager.isAvailable || !cloudKitManager.isSignedIn)
                                .onChange(of: enableiCloudSync) { value in
                                    if value && cloudKitManager.isSignedIn {
                                        // 启用同步时，立即同步一次
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("EnableiCloudSync"),
                                            object: nil
                                        )
                                    }
                                }
                            
                            // 自动同步
                            Toggle("自动同步", isOn: $autoSync)
                                .disabled(!enableiCloudSync || !cloudKitManager.isAvailable || !cloudKitManager.isSignedIn)
                            
                            // 同步信息
                            if let lastSync = cloudKitManager.lastSyncDate {
                                HStack {
                                    Text("上次同步：")
                                        .foregroundColor(.secondary)
                                    Text(lastSync, style: .relative)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .font(.caption)
                            }
                            
                            // 手动同步按钮
                            if enableiCloudSync && cloudKitManager.isSignedIn {
                                Button(action: {
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("ManualiCloudSync"),
                                        object: nil
                                    )
                                }) {
                                    HStack {
                                        if cloudKitManager.isSyncing {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Image(systemName: "arrow.clockwise")
                                        }
                                        Text(cloudKitManager.isSyncing ? "正在同步..." : "立即同步")
                                    }
                                }
                                .disabled(cloudKitManager.isSyncing)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 数据管理
                    GroupBox(label: Label("数据管理", systemImage: "folder")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("所有数据保存在本地tmp文件夹中")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Button("打开数据文件夹") {
                                    if let url = URL(string: "file://\(FileManager.default.currentDirectoryPath)/tmp/") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 关于
                    GroupBox(label: Label("关于", systemImage: "info.circle")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("日历记录应用")
                                .font(.system(size: 14, weight: .medium))
                            Text("版本 1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("一个简洁美观的日历记录应用，支持本地存储和iCloud同步。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 500)
        .background(Color(NSColor.textBackgroundColor))
    }
} 