#!/bin/bash
# 打 deb（产物可直接 dpkg -i 安装）
set -e
V=${1:-1.0}
STAGE=./_pkg
rm -rf $STAGE && mkdir -p $STAGE/DEBIAN \
  $STAGE/var/jb/Library/AxsEQ $STAGE/var/jb/usr/bin

cp out/AxsLevel.dylib axs_load.lua $STAGE/var/jb/Library/AxsEQ/
cp out/axs_lv $STAGE/var/jb/usr/bin/
chmod +x $STAGE/var/jb/usr/bin/axs_lv

cat > $STAGE/DEBIAN/control <<CTL
Package: com.axs.eqlevel
Name: AxsEQ 真实电平载荷
Version: $V
Architecture: iphoneos-arm64
Description: mediaserverd 内真实 PCM 电平（Lua 控制台手动加载，重启失效）
Maintainer: AxsEQ
CTL

cat > $STAGE/DEBIAN/postinst <<'POST'
#!/bin/sh
echo "装好了。用法："
echo "  eqe core"
echo '  core# dofile("/var/jb/Library/AxsEQ/axs_load.lua")'
exit 0
POST
chmod +x $STAGE/DEBIAN/postinst

dpkg-deb --root-owner-group -b $STAGE "AxsEQ_真实电平_$V.deb"
echo "产物：AxsEQ_真实电平_$V.deb"
