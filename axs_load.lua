-- axs_load.lua — 在厂商 EQE 的 mediaserverd Lua 控制台里加载 AxsLevel.dylib
-- 用法：
--   terminal:      eqe core
--   core# 提示符:  dofile("/var/jb/Library/AxsEQ/axs_load.lua")
-- 注意：控制台只回显"表达式返回值"，不显示 print，所以这里 return 字符串。

local out = {}
local function L(s) out[#out+1] = tostring(s) return table.concat(out, " | ") end

-- 1) 找 cffi（厂商自带的模块，名叫 cffi 或 ffi）
local ffi
for _, n in ipairs({ "ffi", "cffi" }) do
    local ok, m = pcall(require, n)
    if ok and m then ffi = m break end
end
if not ffi then return L("没有 cffi 模块") end

pcall(function() ffi.cdef[[
int  axs_status(void);
int  axs_start(void);
int  axs_stop(void);
long axs_frames(void);
long axs_calls(void);
int  axs_fmt(void);
]] end)

-- 2) 依次尝试候选路径（arm64e ABI v2 那个优先）
local h, used
for _, p in ipairs({
    "/var/jb/Library/AxsEQ/AxsLevel.dylib",
    "/var/jb/com.r333d.eqe/AxsLevel.dylib",
}) do
    local ok, res = pcall(function() return ffi.load(p) end)
    if ok and res then h = res used = p break end
end
if not h then return L("dylib 加载失败（多为架构不符：mediaserverd 需要 arm64e）") end

-- 3) 启动
local ok, ret = pcall(function() return h.axs_start() end)
L("loaded " .. used)
L("start=" .. tostring(ret) .. "（1=成功 0=已启动 -10=无MSHook -11=无AudioUnitRender -12=原函数为空）")
L("status=" .. tostring(h.axs_status()) .. "（bit0 钩子 bit1 端口 bit2 写文件）")
L("calls=" .. tostring(h.axs_calls()) .. " frames=" .. tostring(h.axs_frames()))
local okf, fmt = pcall(function() return h.axs_fmt() end)
if okf and fmt then
    local bits = math.floor(fmt / 256)
    local isf  = math.floor(fmt / 16) % 2
    local ch   = fmt % 16
    L(string.format("采样格式=%dbit %s %d通道", bits, isf == 1 and "float" or "整数", ch))
else
    L("fmt 取不到")
end
L("放几秒歌后再执行一次本脚本，calls/frames 应该变大")
return table.concat(out, " | ")
