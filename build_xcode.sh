#!/bin/bash
# 在 macOS 上编译（必须用 Xcode 的 clang 才能生成 arm64e 的 PAC 代码）
# 用法：./build_xcode.sh            产物：AxsLevel.dylib + axs_lv
set -e
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
OUT=./out
mkdir -p $OUT

echo "== 编译 AxsLevel.dylib (arm64e) =="
xcrun --sdk iphoneos clang -target arm64e-apple-ios15.0 \
  -isysroot "$SDK" -dynamiclib -O2 \
  -fobjc-arc -framework Foundation -framework AudioToolbox \
  -install_name /var/jb/Library/AxsEQ/AxsLevel.dylib \
  -o $OUT/AxsLevel.dylib AxsLevel.m

echo "== 编译 axs_lv (arm64e) =="
xcrun --sdk iphoneos clang -target arm64e-apple-ios15.0 \
  -isysroot "$SDK" -O2 -o $OUT/axs_lv axs_lv.c

echo "== 签名（ldid，注意 -S 参数必须连写）=="
if command -v ldid >/dev/null; then
  ldid -Sent.plist $OUT/AxsLevel.dylib
  ldid -Sent.plist $OUT/axs_lv
else
  echo "没装 ldid：用 codesign 假签名也行"
  codesign -s - --entitlements ent.plist -f $OUT/AxsLevel.dylib
  codesign -s - --entitlements ent.plist -f $OUT/axs_lv
fi

echo "== 校验架构（必须是 arm64e）=="
lipo -info $OUT/AxsLevel.dylib
echo "完成：$OUT/"
