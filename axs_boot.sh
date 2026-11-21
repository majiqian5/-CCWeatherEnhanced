#!/bin/sh
ST=/var/mobile/Library/AxsEQ
mkdir -p "$ST" 2>/dev/null
LOG=$ST/boot.log
log(){ echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> $LOG; }

log "boot script start"

# 手动开关
[ -f "$ST/noauto" ] && { log "skip: noauto"; exit 0; }

# 连续失败 3 次就永久停
n=0
[ -f "$ST/fail.count" ] && n=$(cat "$ST/fail.count" 2>/dev/null)
case "$n" in ''|*[!0-9]*) n=0 ;; esac
[ "$n" -ge 3 ] && { log "skip: fail count $n"; exit 0; }

# 再等 200 秒，把开机高峰彻底让过去
log "sleep 200"
sleep 200

mkdir -p /var/tmp/AxsEQ 2>/dev/null
[ -f /var/tmp/AxsEQ/range.txt ] || echo "-42 6" > /var/tmp/AxsEQ/range.txt

PID0=$(pgrep -x mediaserverd 2>/dev/null | head -1)
log "inject start, mediaserverd=$PID0"

echo 'dofile("/var/jb/Library/AxsEQ/axs_load.lua")' | eqe core >/dev/null 2>&1
sleep 6

if /var/jb/usr/bin/axs_lv 2>/dev/null | grep -q "AXS "; then
  PID1=$(pgrep -x mediaserverd 2>/dev/null | head -1)
  if [ "$PID1" = "$PID0" ]; then
    echo 0 > "$ST/fail.count"
    log "ok"
  else
    log "mediaserverd 重启过 $PID0 -> $PID1，关自动加载"
    touch "$ST/noauto"
  fi
else
  n=$((n+1))
  echo $n > "$ST/fail.count"
  log "fail $n（端口没数据）"
  [ "$n" -ge 3 ] && log "连续失败 3 次，停止自动加载"
fi
log "boot script end"
exit 0
