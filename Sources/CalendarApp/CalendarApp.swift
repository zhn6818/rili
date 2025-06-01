import SwiftUI
import AppKit

/**
 * 日历应用主入口
 * 这是整个应用的启动点，配置应用的基本设置和主窗口
 */
@main
struct CalendarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            CalendarView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

// 应用代理类
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用为常规应用（不是只有菜单栏的应用）
        NSApp.setActivationPolicy(.regular)
        
        // 检查是否为签名应用
        if isSignedApp() {
            print("检测到签名应用，初始化CloudKit...")
            // 延迟初始化CloudKit，确保在应用完全启动后进行
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                CloudKitManager.shared.setupCloudKit()
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 当应用被重新打开时，确保窗口可见
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
    
    // 检查应用是否已签名
    private func isSignedApp() -> Bool {
        // 如果是从app bundle运行，而不是直接通过swift run，则认为是签名应用
        let bundlePath = Bundle.main.bundlePath
        return bundlePath.hasSuffix(".app") || bundlePath.contains("/Applications/")
    }
} 