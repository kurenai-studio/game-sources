#!/bin/bash

# 版本管理脚本
# 用于创建标签和发布版本

set -e

# 获取当前版本
CURRENT_VERSION=$(grep -oP '<Version>\K[^<]+' MCGame.csproj)
echo "当前版本: $CURRENT_VERSION"

# 检查是否提供了新版本
if [ -z "$1" ]; then
    echo "用法: $0 <新版本> [发布标题]"
    echo "例如: $0 1.0.1 'Bug Fix Release'"
    exit 1
fi

NEW_VERSION=$1
RELEASE_TITLE=${2:-"Release v$NEW_VERSION"}

# 验证版本格式
if [[ ! $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "错误: 版本格式必须为 X.Y.Z"
    exit 1
fi

echo "更新版本到: $NEW_VERSION"

# 更新项目文件中的版本
sed -i "s/<Version>$CURRENT_VERSION<\/Version>/<Version>$NEW_VERSION<\/Version>/g" MCGame.csproj
sed -i "s/<FileVersion>$CURRENT_VERSION.0<\/FileVersion>/<FileVersion>$NEW_VERSION.0<\/FileVersion>/g" MCGame.csproj
sed -i "s/<AssemblyVersion>$CURRENT_VERSION.0<\/AssemblyVersion>/<AssemblyVersion>$NEW_VERSION.0<\/AssemblyVersion>/g" MCGame.csproj

# 提交版本更改
git add MCGame.csproj
git commit -m "版本更新: $NEW_VERSION

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 创建标签
git tag -a "v$NEW_VERSION" -m "$RELEASE_TITLE"

echo "版本 $NEW_VERSION 已准备就绪"
echo "使用以下命令推送到远程仓库:"
echo "  git push origin master"
echo "  git push origin v$NEW_VERSION"

echo ""
echo "或者使用GitHub Actions手动触发发布:"
echo "  1. 访问 https://github.com/ModerRAS/MCGame/actions"
echo "  2. 选择 'Create Release' workflow"
echo "  3. 点击 'Run workflow'"
echo "  4. 输入版本: $NEW_VERSION"
echo "  5. 输入发布标题: $RELEASE_TITLE"