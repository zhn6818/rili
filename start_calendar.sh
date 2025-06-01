#!/bin/bash

# 日历应用启动脚本 (Swift Package Manager版本)
# 用于快速构建和运行日历应用

set -e

APP_NAME="CalendarApp"

echo "🚀 启动 $APP_NAME..."

# 检查Swift是否安装
if ! command -v swift &> /dev/null; then
    echo "❌ 错误：未找到Swift。请确保已安装Xcode或Swift工具链。"
    exit 1
fi

# 检查是否在正确的目录
if [ ! -f "Package.swift" ]; then
    echo "❌ 错误：未找到Package.swift文件。请确保在项目根目录运行此脚本。"
    exit 1
fi

# 构建并运行应用
echo "🔨 构建应用..."
swift build

echo "🎯 启动应用..."
swift run

echo "🎉 应用已启动！" 