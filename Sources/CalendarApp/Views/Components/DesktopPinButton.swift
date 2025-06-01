import SwiftUI
import AppKit

/**
 * 桌面固定按钮
 * 一个简单的装饰性按钮
 */
struct DesktopPinButton: View {
    @State private var isPinned = false
    
    var body: some View {
        Button(action: {
            isPinned.toggle()
            // 简单地切换状态，但不实际修改窗口属性
            print("按钮点击：\(isPinned ? "已固定" : "未固定")")
        }) {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.2, green: 0.4, blue: 0.5).opacity(0.8))
                )
                .shadow(color: Color.black.opacity(0.3), radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .help(isPinned ? "取消固定到桌面" : "固定到桌面")
    }
} 