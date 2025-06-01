import SwiftUI

/**
 * 主日历视图
 * 显示月历界面，支持日期选择和记录编辑
 */
struct CalendarView: View {
    @StateObject private var calendarModel = CalendarModel()
    @StateObject private var recordManager = DayRecordManager()
    
    // 星期标题
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
    
    // 状态变量，用于触发视图刷新
    @State private var refreshID = UUID()
    
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
            
            Spacer()
            
            // 中间标题
            Text(calendarModel.getMonthTitle())
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // 右侧按钮组
            HStack(spacing: 12) {
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
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 8) {
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
                // 公历日期
                Text("\(date.day)")
                    .font(.system(size: 20, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                    .padding(.top, 4)
                
                // 记录内容预览
                if hasRecord {
                    Text(contentPreview)
                        .font(.system(size: 9))
                        .foregroundColor(contentTextColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 2)
                        .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                }
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: isToday ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .help(hasRecord ? contentPreview : "点击添加记录")
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
        guard let record = recordManager.getRecord(for: date) else {
            return ""
        }
        
        // 限制预览长度
        let content = record.content
        if content.count > 30 {
            let index = content.index(content.startIndex, offsetBy: 30)
            return String(content[..<index]) + "..."
        }
        return content
    }
}

// MARK: - 预览
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .frame(width: 1200, height: 800)
    }
} 