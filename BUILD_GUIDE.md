# 控制中心天气增强版 - GitHub Actions 编译指南

## 快速开始

1. 在 GitHub 创建新仓库
2. 上传本工程所有文件到仓库
3. 推送后自动触发编译
4. 在 Actions 页面下载编译好的 deb

## 手动编译（需要 Mac）

```bash
# 安装 Theos
git clone --recursive https://github.com/theos/theos.git ~/theos
export THEOS=~/theos

# 安装 SDK
git clone https://github.com/theos/sdks.git ~/theos/sdks

# 编译
make clean package FINALPACKAGE=1
```

## 架构说明

- ARCHS = arm64 arm64e（同时支持两种架构）
- iPhone 14 Pro Max 及以上设备需要 arm64e
- 编译产物为 fat binary，兼容所有设备

## 安装

1. 下载编译好的 .deb 文件
2. 用 Sileo/Zebra 安装
3. Respring
4. 控制中心 → 编辑 → 添加「天气」模块

## 功能

- 8种主题、毛玻璃/半透明/实色背景
- 圆角、透明度、边框、阴影自定义
- 4类独立颜色字号、彩虹渐变、动态流动
- 2×2 / 4×2 / 4×4 尺寸
- Open-Meteo API、自动定位/自定义城市
- 6/24小时预报、摄氏/华氏
- 单击/双击/长按/双指自定义动作
- 6大分组 40+ 配置项
