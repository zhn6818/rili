import SwiftUI

/**
 * 主日历视图
 * 显示月历界面，支持日期选择和记录编辑
 */
struct CalendarView: View {
    @StateObject private var calendarModel = CalendarModel()
    @StateObject private var recordManager = DayRecordManager()
    @StateObject private var cloudKitManager = CloudKitManager.shared
    
    // 星期标题
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
    
    // 状态变量，用于触发视图刷新
    @State private var refreshID = UUID()
    @State private var showingSettings = false
    @State private var showingDetail = false  // 是否显示日详情视图
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.25, blue: 0.4),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.2, green: 0.15, blue: 0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 主视图内容
            VStack(spacing: 16) {
                // 月份导航栏
                headerView
                
                // 星期标题行
                weekdayHeaderView
                
                // 日历网格
                calendarGridView
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .id(refreshID) // 使用ID触发视图刷新
        .sheet(isPresented: $calendarModel.showingEditView) {
            if let date = calendarModel.selectedDate {
                EditView(date: date, isPresented: $calendarModel.showingEditView)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings)
        }
        .onAppear {
            // 添加通知监听
            setupNotifications()
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("RecordUpdated"),
                object: nil
            )
        }
    }
    
    // MARK: - 顶部标题栏
    private var headerView: some View {
        HStack(spacing: 20) {
            // 左侧导航按钮
            Button(action: {
                calendarModel.previousMonth()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // 设置按钮
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .help("设置")
            
            Spacer()
            
            // 中间标题
            Text(calendarModel.getMonthTitle())
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // 右侧按钮组
            HStack(spacing: 12) {
                // iCloud状态指示器
                HStack(spacing: 4) {
                    if cloudKitManager.isSyncing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: cloudKitManager.isAvailable && cloudKitManager.isSignedIn ? "icloud" : "icloud.slash")
                            .font(.system(size: 16))
                            .foregroundColor(cloudKitManager.isAvailable ? (cloudKitManager.isSignedIn ? .white : .red) : .orange)
                    }
                    
                    if cloudKitManager.syncError != nil {
                        Text("!")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
                .help(iCloudStatusText)
                .onTapGesture {
                    if cloudKitManager.isAvailable && cloudKitManager.isSignedIn && !cloudKitManager.isSyncing {
                        recordManager.syncWithiCloud()
                    }
                }
                
                // 快速添加今日记录按钮
                Button(action: {
                    calendarModel.selectDate(Date())
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .help("添加今日记录")
                
                // 右侧导航按钮
                Button(action: {
                    calendarModel.nextMonth()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - 星期标题行
    private var weekdayHeaderView: some View {
        HStack(spacing: 2) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - 日历网格
    private var calendarGridView: some View {
        let days = calendarModel.getDaysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(days, id: \.self) { date in
                DayCell(
                    date: date,
                    isInCurrentMonth: calendarModel.isInCurrentMonth(date),
                    isToday: calendarModel.isToday(date),
                    hasRecord: recordManager.hasRecord(for: date),
                    onTap: {
                        calendarModel.selectDate(date)
                    },
                    recordManager: recordManager
                )
            }
        }
    }
    
    // MARK: - 通知设置
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RecordUpdated"),
            object: nil,
            queue: .main
        ) { _ in
            // 强制刷新recordManager的数据
            self.recordManager.objectWillChange.send()
            // 刷新视图
            self.refreshID = UUID()
        }
    }
}

/**
 * 日期单元格视图
 */
struct DayCell: View {
    let date: Date
    let isInCurrentMonth: Bool
    let isToday: Bool
    let hasRecord: Bool
    let onTap: () -> Void
    
    // 添加记录管理器获取内容预览
    @ObservedObject var recordManager: DayRecordManager
    
    var body: some View {
        Button(action: {
            print("点击日期单元格: \(date)")
            onTap()
        }) {
            VStack(spacing: 2) {
                // 顶部日期栏
                HStack {
                    Text("\(date.day)")
                        .font(.system(size: 20, weight: isToday ? .bold : .medium))
                        .foregroundColor(textColor)
                        .padding(.top, 4)
                        .padding(.leading, 6)
                    
                    Spacer()
                    
                    // 显示记录数量和标记
                    if hasRecord {
                        HStack(spacing: 4) {
                            // 记录数量
                            let count = recordManager.recordCount(for: date)
                            if count > 1 {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Color.orange.opacity(0.8))
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.trailing, 6)
                    }
                }
                
                // 记录内容预览
                if hasRecord {
                    recordsContentView
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                } else {
                    Spacer()
                }
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isToday ? 2 : hasRecord ? 1 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .help(hasRecord ? contentPreview : "点击添加记录")
    }
    
    // 多条记录内容视图 - 简化为纯展示
    private var recordsContentView: some View {
        VStack(alignment: .leading, spacing: 1) {
            let records = recordManager.getRecords(for: date)
            let displayRecords = Array(records.prefix(3)) // 最多显示3条记录
            
            ForEach(displayRecords.indices, id: \.self) { index in
                let record = displayRecords[index]
                let firstLine = record.content.split(separator: "\n").first ?? ""
                
                // 每条记录的展示区域
                HStack(spacing: 2) {
                    // 记录标记
                    Rectangle()
                        .fill(recordColor(index: index))
                        .frame(width: 2)
                    
                    // 记录内容第一行
                    Text(String(firstLine))
                        .font(.system(size: 10))
                        .foregroundColor(contentTextColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 1)
            }
            
            // 如果还有更多记录，显示省略号
            if records.count > 3 {
                Text("还有 \(records.count - 3) 条记录...")
                    .font(.system(size: 9))
                    .foregroundColor(contentTextColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 1)
            }
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
    
    // 根据记录索引返回不同颜色
    private func recordColor(index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red]
        return colors[index % colors.count]
    }
    
    // MARK: - 计算属性
    
    private var textColor: Color {
        if !isInCurrentMonth {
            return .white.opacity(0.3)
        } else if isToday {
            return .white
        } else {
            return .white.opacity(0.9)
        }
    }
    
    private var contentTextColor: Color {
        if !isInCurrentMonth {
            return .white.opacity(0.3)
        } else if isToday {
            return .white.opacity(0.9)
        } else {
            return .white.opacity(0.7)
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return Color.white.opacity(0.2)
        } else if !isInCurrentMonth {
            return Color.white.opacity(0.02)
        } else if hasRecord {
            return Color.blue.opacity(0.15)
        } else if date.isWeekend {
            return Color.white.opacity(0.08)
        } else {
            return Color.white.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        if isToday {
            return Color.white.opacity(0.8)
        } else if hasRecord {
            return Color.blue.opacity(0.3)
        } else {
            return .clear
        }
    }
    
    // 获取内容预览
    private var contentPreview: String {
        let records = recordManager.getRecords(for: date)
        if records.isEmpty {
            return ""
        }
        
        let count = records.count
        let firstRecord = records.first?.content ?? ""
        let preview = String(firstRecord.prefix(30))
        
        if count == 1 {
            return firstRecord.count > 30 ? preview + "..." : preview
        } else {
            return "\(count)条记录: " + (firstRecord.count > 20 ? String(firstRecord.prefix(20)) + "..." : preview)
        }
    }
}

// MARK: - 扩展视图
extension CalendarView {
    private var iCloudStatusText: String {
        if cloudKitManager.isSyncing {
            return "正在同步..."
        } else if let error = cloudKitManager.syncError {
            return error
        } else if !cloudKitManager.isAvailable {
            return "iCloud服务暂不可用"
        } else if cloudKitManager.isSignedIn {
            if let lastSync = cloudKitManager.lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                return "上次同步: \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
            }
            return "点击同步iCloud"
        } else {
            return "未登录iCloud"
        }
    }
}

// MARK: - 预览
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .frame(width: 1200, height: 800)
    }
} 