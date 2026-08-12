#!/bin/bash
# 手机端一键编译脚本
# 使用方法：在 NewTerm 中运行 bash build.sh

set -e

echo "========================================="
echo "  CCWeatherEnhanced 一键编译脚本"
echo "========================================="

# 检查 Theos
if [ -z "$THEOS" ]; then
    if [ -d "/opt/theos" ]; then
        export THEOS=/opt/theos
    elif [ -d "$HOME/theos" ]; then
        export THEOS=$HOME/theos
    else
        echo "[错误] 未找到 Theos，请先安装："
        echo "  apt install theos"
        echo "  或从 https://theos.dev 安装"
        exit 1
    fi
fi

echo "[信息] THEOS = $THEOS"
export PATH=$THEOS/bin:$PATH

# 检查依赖
echo "[信息] 检查编译依赖..."
for cmd in clang ldid dpkg-deb make; do
    if ! command -v $cmd &> /dev/null; then
        echo "[错误] 缺少 $cmd，请运行：apt install $cmd"
        exit 1
    fi
done

# 进入脚本所在目录
cd "$(dirname "$0")"

echo "[信息] 清理旧编译..."
make clean > /dev/null 2>&1 || true

echo "[信息] 开始编译..."
if make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless; then
    echo ""
    echo "========================================="
    echo "  编译成功！"
    echo "========================================="
    echo ""
    DEB_FILE=$(ls -t packages/*.deb 2>/dev/null | head -1)
    if [ -n "$DEB_FILE" ]; then
        echo "deb 文件：$DEB_FILE"
        echo ""
        echo "安装命令："
        echo "  dpkg -i $DEB_FILE"
        echo "  killall -9 SpringBoard"
        echo ""
        read -p "是否现在安装？(y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "[信息] 正在安装..."
            dpkg -i "$DEB_FILE"
            echo "[信息] 重启 SpringBoard..."
            killall -9 SpringBoard
            echo "[完成] 已安装并重启！"
        fi
    fi
else
    echo ""
    echo "[错误] 编译失败，请检查上面的错误信息。"
    exit 1
fi
