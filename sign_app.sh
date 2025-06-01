#!/bin/bash

# 日历应用签名脚本
# 用于签名应用以使用iCloud功能

set -e

APP_NAME="CalendarApp"
BUNDLE_ID="com.zhn6818.CalendarApp"
# 您需要从开发者账号中获取团队ID
# 可以在developer.apple.com -> Membership中找到
TEAM_ID="YOUR_TEAM_ID" # 替换为您的开发者Team ID

echo "🔒 为 $APP_NAME 签名..."

# 构建应用
echo "🔨 构建应用..."
swift build -c release

# 创建应用包
echo "📦 创建应用包..."
BUILD_PATH=".build/release/$APP_NAME"
APP_PATH="./build/$APP_NAME.app"

# 创建应用目录结构
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# 复制可执行文件
cp "$BUILD_PATH" "$APP_PATH/Contents/MacOS/"

# 创建Info.plist
cp "Sources/CalendarApp/Info.plist" "$APP_PATH/Contents/"

# 修改Info.plist中的Bundle ID
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP_PATH/Contents/Info.plist"

# 复制entitlements文件
cp "Sources/CalendarApp/CalendarApp.entitlements" "$APP_PATH/"

# 确保脚本可执行
chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"

# 签名应用
echo "✍️ 签名应用..."
codesign --force --sign "Developer ID Application: $TEAM_ID" --entitlements "$APP_PATH/CalendarApp.entitlements" "$APP_PATH"

echo "✅ 签名完成！应用位于: $APP_PATH"
echo "🔄 请运行以下命令启动应用:"
echo "open $APP_PATH"
echo ""
echo "⚠️ 注意: 您需要在System Preferences -> iCloud中登录您的iCloud账号(zhn6818@icloud.com)" 