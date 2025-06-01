import Foundation

/**
 * Date扩展
 * 提供日期相关的便利方法
 */
extension Date {
    
    /**
     * 获取日期的天数
     */
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    /**
     * 获取日期的月份
     */
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    /**
     * 获取日期的年份
     */
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    /**
     * 获取星期几（1=周日，2=周一，...，7=周六）
     */
    var weekday: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    
    /**
     * 获取中文星期名称
     */
    var chineseWeekday: String {
        let weekdays = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
        return weekdays[weekday - 1]
    }
    
    /**
     * 获取简短的中文星期名称
     */
    var shortChineseWeekday: String {
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        return weekdays[weekday - 1]
    }
    
    /**
     * 检查是否为今天
     */
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /**
     * 检查是否为周末
     */
    var isWeekend: Bool {
        return Calendar.current.isDateInWeekend(self)
    }
    
    /**
     * 获取月份的第一天
     */
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /**
     * 获取月份的最后一天
     */
    var endOfMonth: Date {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth),
              let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
            return self
        }
        return endOfMonth
    }
    
    /**
     * 添加指定天数
     */
    func addingDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /**
     * 添加指定月数
     */
    func addingMonths(_ months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    /**
     * 格式化为字符串
     */
    func formatted(_ format: String, locale: Locale = Locale(identifier: "zh_CN")) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    /**
     * 获取相对于另一个日期的天数差
     */
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: date)
        return components.day ?? 0
    }
}

/**
 * Calendar扩展
 * 提供日历相关的便利方法
 */
extension Calendar {
    
    /**
     * 获取指定月份的天数
     */
    func numberOfDaysInMonth(for date: Date) -> Int {
        guard let range = self.range(of: .day, in: .month, for: date) else {
            return 0
        }
        return range.count
    }
    
    /**
     * 获取指定日期所在月份的第一天是星期几
     */
    func firstWeekdayOfMonth(for date: Date) -> Int {
        let firstDay = date.startOfMonth
        return self.component(.weekday, from: firstDay)
    }
    
    /**
     * 检查两个日期是否在同一天
     */
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return self.isDate(date1, inSameDayAs: date2)
    }
    
    /**
     * 检查两个日期是否在同一月
     */
    func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        return self.isDate(date1, equalTo: date2, toGranularity: .month)
    }
    
    /**
     * 检查两个日期是否在同一年
     */
    func isSameYear(_ date1: Date, _ date2: Date) -> Bool {
        return self.isDate(date1, equalTo: date2, toGranularity: .year)
    }
} 