# 日历记录应用 (Calendar App)

一个简洁美观的 macOS 桌面日历应用，支持查看日历和添加每日记录。

## 功能特性

- 📅 **日历视图**：清晰展示月历，支持月份切换
- ✏️ **日记功能**：点击任意日期添加或编辑记录
- 🌙 **农历显示**：显示农历日期、节气和传统节日
- 💾 **本地存储**：所有记录保存在本地 `tmp/dayRecords.json` 文件中
- 🎨 **美观界面**：深色主题设计，渐变背景

## 项目结构

```
rili/
├── Sources/
│   └── CalendarApp/
│       ├── CalendarApp.swift          # 应用入口
│       ├── Models/
│       │   ├── CalendarModel.swift    # 日历数据模型
│       │   └── DayRecord.swift        # 日记录模型和管理器
│       ├── Views/
│       │   ├── CalendarView.swift     # 主日历视图
│       │   ├── EditView.swift         # 编辑视图
│       │   └── Components/
│       │       ├── CalendarHeader.swift    # 日历头部
│       │       ├── DesktopPinButton.swift  # 桌面固定按钮
│       │       └── QuickEditButton.swift   # 快速编辑按钮
│       ├── Utils/
│       │   ├── ChineseCalendar.swift  # 农历计算工具
│       │   ├── DateExtensions.swift   # 日期扩展
│       │   ├── CustomEditWindow.swift # 自定义编辑窗口
│       │   └── BasicEditDialog.swift  # 基础编辑对话框
│       ├── Resources/              # 资源文件
│       └── Info.plist             # 应用配置文件
├── tmp/                           # 数据存储目录（自动创建）
│   └── dayRecords.json           # 日记录数据文件
├── Package.swift                  # Swift包配置
├── start_calendar.sh              # 快速启动脚本
├── .gitignore                     # Git忽略配置
└── README.md                      # 本文件
```

## 使用方法

### 运行应用

1. 确保已安装 Xcode 和 Swift 开发环境
2. 在项目根目录运行：
   ```bash
   swift run
   ```

### 基本操作

- **查看日历**：应用启动后显示当前月份的日历
- **切换月份**：点击左右箭头切换上下月
- **添加记录**：点击任意日期弹出编辑窗口
- **编辑记录**：
  - 在编辑窗口中输入内容
  - 按 Enter 或点击"保存"按钮保存
  - 按 ESC 或点击"取消"按钮取消编辑
- **删除记录**：在编辑窗口中点击"删除"按钮

### 数据存储

- 所有记录自动保存在 `tmp/dayRecords.json` 文件中
- 首次运行时会自动创建 `tmp` 目录
- 数据以 JSON 格式存储，可以手动备份

## 技术实现

### 编辑窗口问题修复历程

1. **初始问题**：SwiftUI TextEditor 无法正常工作
2. **尝试方案**：
   - NSViewRepresentable 包装 NSTextView
   - 原生窗口控制器
   - 系统文件编辑器
   - NSAlert 对话框
3. **最终方案**：使用 NSPanel + NSTextView 创建自定义编辑窗口
4. **关键修复**：
   - 确保所有 UI 操作在主线程执行
   - 正确设置文本视图的焦点
   - 使用文件系统替代 UserDefaults 存储数据

### 技术栈

- **语言**：Swift 5
- **框架**：SwiftUI + AppKit
- **平台**：macOS 10.15+

## 开发说明

### 编译项目

```bash
swift build
```

### 运行测试

```bash
swift test
```

### 清理构建

```bash
swift package clean
rm -rf .build
```

## 注意事项

- 应用需要 macOS 10.15 或更高版本
- 数据存储在本地，卸载应用不会自动删除数据
- 建议定期备份 `tmp/dayRecords.json` 文件

## 后续改进计划

- [ ] 添加数据导出功能
- [ ] 支持多种视图模式（周视图、年视图）
- [ ] 添加搜索功能
- [ ] 支持标签和分类
- [ ] 添加提醒功能
- [ ] 支持 iCloud 同步

## 许可证

本项目仅供学习和个人使用。 