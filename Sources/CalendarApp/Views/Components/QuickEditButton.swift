import SwiftUI

/**
 * 快速编辑按钮
 * 浮动在界面上方的快速添加记录按钮
 */
struct QuickEditButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14))
                
                Text("快速记录")
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(red: 0.2, green: 0.4, blue: 0.5).opacity(0.8))
            )
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.3), radius: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .help("点击添加今日记录")
    }
} 