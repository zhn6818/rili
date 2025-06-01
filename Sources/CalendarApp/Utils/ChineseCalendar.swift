import Foundation

/**
 * 中国农历计算工具
 * 提供农历日期转换和节日信息
 */
class ChineseCalendar {
    
    // 农历月份名称
    private static let lunarMonths = ["正月", "二月", "三月", "四月", "五月", "六月",
                                     "七月", "八月", "九月", "十月", "冬月", "腊月"]
    
    // 农历日期名称
    private static let lunarDays = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
                                   "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
                                   "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
    
    // 节气名称
    private static let solarTerms = ["小寒", "大寒", "立春", "雨水", "惊蛰", "春分",
                                    "清明", "谷雨", "立夏", "小满", "芒种", "夏至",
                                    "小暑", "大暑", "立秋", "处暑", "白露", "秋分",
                                    "寒露", "霜降", "立冬", "小雪", "大雪", "冬至"]
    
    // 传统节日
    private static let traditionalFestivals: [String: String] = [
        "01-01": "元旦",
        "02-14": "情人节",
        "03-08": "妇女节",
        "03-12": "植树节",
        "04-01": "愚人节",
        "05-01": "劳动节",
        "05-04": "青年节",
        "06-01": "儿童节",
        "07-01": "建党节",
        "08-01": "建军节",
        "09-10": "教师节",
        "10-01": "国庆节",
        "12-25": "圣诞节"
    ]
    
    // 农历节日（简化版本，实际应该根据农历计算）
    private static let lunarFestivals: [String: String] = [
        "01-01": "春节",
        "01-15": "元宵节",
        "05-05": "端午节",
        "07-07": "七夕节",
        "08-15": "中秋节",
        "09-09": "重阳节",
        "12-08": "腊八节",
        "12-23": "小年"
    ]
    
    /**
     * 获取指定日期的农历信息
     */
    static func getLunarInfo(for date: Date) -> String {
        // 这里使用简化的农历计算
        // 实际项目中应该使用更精确的农历算法
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        
        // 简化的农历日期计算（仅作演示）
        let lunarMonth = (month - 1 + 11) % 12
        let lunarDay = (day + 10) % 30
        
        let monthName = lunarMonths[lunarMonth]
        let dayName = lunarDays[min(lunarDay, lunarDays.count - 1)]
        
        return "\(monthName)\(dayName)"
    }
    
    /**
     * 获取指定日期的节日信息
     */
    static func getFestival(for date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        let dateString = formatter.string(from: date)
        
        // 检查公历节日
        if let festival = traditionalFestivals[dateString] {
            return festival
        }
        
        // 检查农历节日（简化版本）
        if let lunarFestival = lunarFestivals[dateString] {
            return lunarFestival
        }
        
        // 检查特殊节日
        return getSpecialFestival(for: date)
    }
    
    /**
     * 获取特殊节日（如母亲节、父亲节等）
     */
    private static func getSpecialFestival(for date: Date) -> String? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let weekOfMonth = calendar.component(.weekOfMonth, from: date)
        
        // 母亲节：5月第二个星期日
        if month == 5 && weekday == 1 && weekOfMonth == 2 {
            return "母亲节"
        }
        
        // 父亲节：6月第三个星期日
        if month == 6 && weekday == 1 && weekOfMonth == 3 {
            return "父亲节"
        }
        
        // 感恩节：11月第四个星期四
        if month == 11 && weekday == 5 && weekOfMonth == 4 {
            return "感恩节"
        }
        
        return nil
    }
    
    /**
     * 获取节气信息
     */
    static func getSolarTerm(for date: Date) -> String? {
        // 简化的节气计算
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        // 这里使用简化的节气日期（实际应该使用精确的天文计算）
        let solarTermDates: [String: String] = [
            "1-6": "小寒", "1-20": "大寒",
            "2-4": "立春", "2-19": "雨水",
            "3-6": "惊蛰", "3-21": "春分",
            "4-5": "清明", "4-20": "谷雨",
            "5-6": "立夏", "5-21": "小满",
            "6-6": "芒种", "6-21": "夏至",
            "7-7": "小暑", "7-23": "大暑",
            "8-8": "立秋", "8-23": "处暑",
            "9-8": "白露", "9-23": "秋分",
            "10-8": "寒露", "10-24": "霜降",
            "11-8": "立冬", "11-22": "小雪",
            "12-7": "大雪", "12-22": "冬至"
        ]
        
        let key = "\(month)-\(day)"
        return solarTermDates[key]
    }
    
    /**
     * 检查是否为休息日
     */
    static func isHoliday(for date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // 周末
        if weekday == 1 || weekday == 7 {
            return true
        }
        
        // 检查是否为法定节假日
        return getFestival(for: date) != nil
    }
} 