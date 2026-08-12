# 控制中心天气增强版 CCWeatherEnhanced v2.0.0

功能拉满的 iOS 控制中心天气美化插件，支持 NathanLR + ElleKit (rootless)，兼容 iOS 15.0+。

## 功能特性

### 外观
- 8 种预设主题（跟随系统/深色/浅色/海洋蓝/日落橙/森林绿/梦幻紫/黑白极简）
- 毛玻璃 / 半透明 / 实色三种背景样式
- 圆角大小可调（0~40）
- 模块透明度可调（0.2~1.0）
- 边框开关与粗细调节
- 阴影效果（半径/透明度可调）
- 天气图标大小可调
- 温度/城市/小时预报字体大小独立可调

### 字体颜色
- 自定义 RGB 颜色
- 温度、城市、天气状态、小时预报可分别设置颜色
- 彩虹渐变文字
- 彩虹动态流动效果（速度可调）
- 渐变方向可调（水平/垂直/对角）

### 模块尺寸
- 小：2×2
- 横向：4×2
- 大：4×4
- 动态尺寸模式
- 内容根据尺寸自动重新排版

### 天气内容
- 当前温度、最高/最低温度
- 天气状况、降水概率
- 当前城市（自动定位/自定义）
- 未来小时预报（6小时/24小时滚动）
- 摄氏/华氏切换
- 自动刷新间隔（5/15/30/60分钟）
- 使用 Open-Meteo 免费 API，无需 API Key

### 交互
- 单击：展开/收起 / 刷新 / 设置 / 切换主题 / 无
- 双击：可自定义
- 长按：可自定义
- 双指点击：可自定义
- 展开状态显示更多天气信息

### 设置
独立 Preference Bundle，分组管理：外观、文字、布局、天气、交互、高级。

## 工程结构

```
CCWeatherEnhanced/
├── Makefile                    # 顶层编译文件
├── control                     # deb 包控制信息
├── CCWeatherConfig.h           # 公共配置（键名/枚举/默认值）
├── CCWeatherModule/            # 控制中心模块 Bundle
│   ├── Makefile
│   ├── Info.plist
│   ├── CCWeatherModule.h/m     # 模块主类（CCUIContentModule）
│   ├── CCWeatherViewController.h/m  # 主视图控制器
│   ├── CCWThemeManager.h/m     # 主题与偏好管理
│   ├── CCWRainbowLabel.h/m     # 彩虹渐变文字标签
│   ├── CCWeatherManager.h/m    # 天气数据获取
│   ├── CCWeatherData.h/m       # 数据模型
│   └── Resources/              # 天气图标（29个）
├── CCWeatherTweak/             # 注入 Tweak
│   ├── Makefile
│   ├── Tweak.xm                # Logos 注入代码
│   └── CCWeatherTweak.plist    # 注入过滤
├── CCWeatherPrefs/             # 设置插件 Bundle
│   ├── Makefile
│   ├── Info.plist
│   ├── CCWRootListController.h/mm  # 设置主控制器
│   └── Resources/              # 设置图标
└── layout/                     # 额外安装文件
    └── Library/PreferenceLoader/Preferences/CCWeatherPrefs.plist
```

## 编译方法

### 方法一：手机端 NewTerm 编译（推荐，无需 Mac）

1. 确保已安装：`theos`、`clang`、`ldid`、`dpkg`
   ```
   apt install theos clang ldid dpkg
   ```

2. 设置环境变量：
   ```
   export THEOS=/opt/theos
   export PATH=$THEOS/bin:$PATH
   ```

3. 进入工程目录编译：
   ```
   cd CCWeatherEnhanced
   make clean package FINALPACKAGE=1
   ```

4. 生成的 deb 在 `./packages/` 目录下。

### 方法二：GitHub Actions 远程编译

1. 将工程推送到 GitHub 仓库
2. 创建 `.github/workflows/build.yml`：
   ```yaml
   name: Build
   on: [push]
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - name: Install Theos
           run: |
             git clone --recursive https://github.com/theos/theos.git $THEOS
             echo "THEOS=$THEOS" >> $GITHUB_ENV
         - name: Build
           run: make clean package FINALPACKAGE=1
         - uses: actions/upload-artifact@v3
           with:
             path: packages/*.deb
   ```

### 方法三：Mac 本地编译

```bash
export THEOS=/opt/theos
make clean package FINALPACKAGE=1
```

## 安装

```bash
# 手机端
dpkg -i com.axs.ccweatherenhanced_2.0.0_iphoneos-arm64.deb
killall -9 SpringBoard

# 或通过 Sileo/Zebra 安装
```

## 注意事项

1. **首次使用**：安装后到设置 → 控制中心天气增强版 中配置，然后添加控制中心模块。
2. **定位权限**：自动定位需要在设置中开启定位权限。
3. **网络**：天气数据来自 Open-Meteo，需要网络连接。
4. **rootless**：本插件已配置为 rootless 方案，安装路径为 `/var/jb/Library/`。
5. **安全模式**：如果进入安全模式，请检查 `/var/mobile/Library/Logs/CrashReporter/` 下的崩溃日志。

## 与原版的区别

- 完全重写模块，不再依赖原版二进制
- 新增 8 种主题、彩虹渐变、动态流动
- 新增模块尺寸切换（2×2 / 4×2 / 4×4）
- 新增完整的交互自定义
- 新增 24 小时滚动预报
- 修复原版可能的兼容问题
- 支持 NathanLR + ElleKit rootless

## 故障排查

### 模块不显示
1. 确认已在控制中心编辑中添加"天气增强版"
2. 检查 `dpkg -l | grep ccweather` 是否安装成功
3. 重启 SpringBoard

### 天气不更新
1. 检查网络连接
2. 检查定位权限（设置 → 隐私 → 定位服务）
3. 在设置中点击"应用并刷新"

### 进入安全模式
1. 查看崩溃日志
2. 尝试关闭彩虹动画（可能某些设备不兼容）
3. 联系开发者并提供日志

## 版本历史

- v2.0.0：完全重写，功能拉满版
- v1.0.5：原版基础功能
