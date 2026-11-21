# AxsEQ 真实电平载荷 v1.7（源码）

mediaserverd 内取真实 PCM，算出 10 段频谱，30Hz 推到 127.0.0.1:47923。
v1.7 重点：修 NaN 永久卡死。

## 文件说明

| 文件 | 作用 |
|---|---|
| AxsLevel.m | 载荷本体（注入 AudioUnitRender 取样本 → RBJ 带通 10 段 → 平滑 → TCP 推送） |
| axs_lv.c | 终端读数工具，连 47923 打 20 行 |
| axs_load.lua | 在 eqe core 的 Lua 控制台里 ffi 加载 dylib 并 start |
| ent.plist | 签名权限（platform-application 等） |
| AxsTcpLevels.m | 上一代 TCP 直推实现，备用 |
| Makefile / build_xcode.sh / make_deb.sh | 本地编译与打包 |
| .github/workflows/build-axslevel.yml | GitHub Action 全自动编译 arm64e |

## 编译（推荐 GitHub Action，唯一能出 arm64e 的方式）

1. 把整个目录推到仓库（.github/workflows/ 要在仓库根）
2. Actions 跑 build-axslevel
3. 下载 artifact axslevel-arm64e

## 编译（本地 macOS 有 Xcode 也行）

    sh build_xcode.sh

Linux 上用 ld64.lld 不行：它不支持 -arch arm64e，链接直接报
`missing or unsupported -arch arm64e`，别浪费时间。

## 装机

    dpkg -i --force-overwrite <deb>

落地路径：
- /var/jb/Library/AxsEQ/AxsLevel.dylib
- /var/jb/Library/AxsEQ/axs_load.lua
- /var/jb/usr/bin/axs_lv

## 用法

    axs_on            # 注入 + 跑一次读数
    axs_lv            # 只看读数

## v1.7 改了什么（7 处 isfinite）

1. 输入样本非有限值按 0
2. bq_run 出口 NaN → 清该段 x1/x2/y1/y2
3. bq_bandpass 采样率非法退回 44100
4. bands_init 系数 NaN → 整组按 44100 重算
5. feed 里 span<=5 退回 38.0，v / prev 都夹一次
6. srv_thread 发送前把 gBand 洗成 0
7. feed_from float32 分支：非有限样本过半 → 改判 int16 重解

原理：NaN 与任何数比较为假，`if(v<0)/if(v>100)` 夹不住它，
一旦进滤波器就把状态永久污染，所以必须在四个入口全部堵。

## 判读

安静 5~25，放歌 30~80，鼓点 90~100。
某段长期 0.00 正常（高频无能量）。出现 nan 说明状态被污染，
v1.7 之前要 killall -9 mediaserverd 才能恢复。

## 量程

/var/tmp/AxsEQ/range.txt，默认 `-42 6`，每秒重读，仅当 hi > lo+5 生效。
收窄成 `-38 0` 读数更满，`-46 4` 更保守。
