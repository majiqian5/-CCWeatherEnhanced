# AxsEQ 开机自动加载（SpringBoard 延迟触发版）

不依赖 launchd，不受 iOS 16 launchd 第三方面 daemon bug 影响。

## 原理

一个极小的 dylib 注入 SpringBoard，构造时只做一件事：
用 posix_spawn 起一个脱离会话的后台 shell，跑 axs_boot.sh。
脚本里再等 200 秒才执行注入。

好处：
- 系统启动阶段什么都不做，不可能造成启动循环
- SpringBoard 崩了最多注销一次，不会卡开机
- 注入时 mediaserverd 早已稳定运行

## 文件

- AxsAutoLoad.m          注入 SpringBoard 的 dylib 源码
- AxsAutoLoad.plist      MobileSubstrate 白名单（com.apple.springboard）
- axs_boot.sh            延迟注入脚本
- ent.plist              签名权限
- .github/workflows/build-autoload.yml

## 编译

推到仓库根目录，跑 build-autoload，下载 artifact autoload-arm64e。
本地 Linux 编不了 arm64e，必须 macOS/Xcode 或 Action。

## 装机

dylib 放 /var/jb/Library/MobileSubstrate/DynamicLibraries/
plist 同目录，脚本放 /var/jb/usr/bin/axs_boot.sh 并 chmod 755

## 日志

- /var/mobile/Library/AxsEQ/tweak.log   dylib 是否被加载、是否 spawn 成功
- /var/mobile/Library/AxsEQ/boot.log    脚本执行到哪一步

## 开关

touch /var/mobile/Library/AxsEQ/noauto          关
rm -f /var/mobile/Library/AxsEQ/noauto /var/mobile/Library/AxsEQ/fail.count   恢复
