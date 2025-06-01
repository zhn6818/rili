import Foundation
import SwiftUI

/**
 * 日历数据模型
 * 管理日历的显示状态和数据
 */
class CalendarModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var selectedDate: Date?
    @Published var showingEditView = false
    
    private let calendar = Calendar.current
    
    /**
     * 获取当前月份的所有日期
     */
    func getDaysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        // 计算需要显示的第一天（包括上个月的日期）
        let daysFromPreviousMonth = (firstWeekday - 1) % 7
        guard let startDate = calendar.date(byAdding: .day, value: -daysFromPreviousMonth, to: firstOfMonth) else {
            return []
        }
        
        var days: [Date] = []
        var currentDay = startDate
        
        // 生成6周的日期（42天）
        for _ in 0..<42 {
            days.append(currentDay)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                break
            }
            currentDay = nextDay
        }
        
        return days
    }
    
    /**
     * 检查日期是否在当前月份
     */
    func isInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentDate, toGranularity: .month)
    }
    
    /**
     * 检查日期是否是今天
     */
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    /**
     * 获取月份标题
     */
    func getMonthTitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentDate)
    }
    
    /**
     * 获取星期标题
     */
    func getWeekdayTitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: currentDate)
    }
    
    /**
     * 切换到上个月
     */
    func previousMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else {
            return
        }
        currentDate = newDate
    }
    
    /**
     * 切换到下个月
     */
    func nextMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else {
            return
        }
        currentDate = newDate
    }
    
    /**
     * 选择日期
     */
    func selectDate(_ date: Date) {
        selectedDate = date
        showingEditView = true
        print("日期已选择: \(date), 显示编辑视图")
    }
    
    /**
     * 关闭编辑视图
     */
    func closeEditView() {
        showingEditView = false
        selectedDate = nil
        print("编辑视图已关闭")
    }
} 