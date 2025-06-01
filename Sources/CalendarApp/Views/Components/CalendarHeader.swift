import SwiftUI

/**
 * 日历标题栏
 * 显示在应用顶部的日期和星期信息栏
 */
struct CalendarHeader: View {
    let date: Date
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // 日期部分
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(dayNumber)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(chineseDay)")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.8))
                }
                .frame(width: 100, height: 80)
                .padding(.leading, 20)
                .background(Color(red: 0.2, green: 0.4, blue: 0.5))
                
                // 星期部分
                Text("星期\(weekdayString)")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(Color(red: 0.2, green: 0.4, blue: 0.5).opacity(0.8))
                    
                // 温度部分
                VStack(alignment: .trailing) {
                    Text("\(temperature)°")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(weatherCondition)")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.8))
                }
                .frame(width: 120, height: 80)
                .padding(.trailing, 20)
                .background(Color(red: 0.2, green: 0.4, blue: 0.5).opacity(0.7))
            }
            .cornerRadius(8)
        }
    }
    
    // 计算当天日期数字
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    // 获取农历日期
    private var chineseDay: String {
        return ChineseCalendar.getLunarInfo(for: date)
    }
    
    // 获取星期几字符串
    private var weekdayString: String {
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return weekdays[weekday - 1]
    }
    
    // 模拟天气数据
    private var temperature: Int {
        return 21 // 模拟温度
    }
    
    private var weatherCondition: String {
        return "多云" // 模拟天气状况
    }
} 