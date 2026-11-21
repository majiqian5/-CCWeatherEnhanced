//
//  AxsLevel.m — mediaserverd 内真实音频电平载荷（v1.2）
//  由厂商 EQE 的 Lua 控制台手动加载：eqe core → dofile("/var/jb/Library/AxsEQ/axs_load.lua")
//  必须用 Xcode 的 Apple clang 编 arm64e（Linux 工具链没有 PAC 代码，一挂钩就崩）
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#include <dlfcn.h>
#include <pthread.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>

#define AXS_BANDS   10
#define AXS_PORT    47923
#define AXS_TMP     "/var/tmp/AxsEQ"
#define AXS_LEVELS  AXS_TMP "/levels.txt"

// ---------------------------------------------------------------- 状态
static volatile int  gHookOK  = 0;
static volatile long gCalls   = 0;
static volatile long gFrames  = 0;
static volatile int  gSrvOK   = 0;
static volatile int  gWriteOK = 0;

static double gBand[AXS_BANDS];
static pthread_mutex_t gLock = PTHREAD_MUTEX_INITIALIZER;

__attribute__((visibility("default"))) int  axs_status(void) { return (gHookOK<<0)|(gSrvOK<<1)|(gWriteOK<<2); }
__attribute__((visibility("default"))) long axs_frames(void) { return gFrames; }
__attribute__((visibility("default"))) long axs_calls(void)  { return gCalls;  }

// 采样格式（运行时向 AudioUnit 查询）：bit8.. = 位宽，bit4 = float，bit0..3 = 通道数
static volatile int gFmtBits = 0;
static volatile int gFmtFloat = 0;
static volatile int gFmtCh = 1;
static volatile int gFmtReady = 0;
static volatile double gDbLo = -40.0;   // 量程底（对应 0）
static volatile double gDbHi = -2.0;    // 量程顶（对应 100）
static volatile double gSampleRate = 44100.0;

__attribute__((visibility("default"))) int axs_fmt(void) {
    return (gFmtBits << 8) | (gFmtFloat << 4) | (gFmtCh & 0xF);
}

// ---------------------------------------------------------------- 10 段 biquad
typedef struct { double b0,b1,b2,a1,a2; double x1,x2,y1,y2; } Biquad;
static Biquad gF[AXS_BANDS];

static void bq_bandpass(Biquad *q, double f0, double Q, double sr) {
    if (!(sr >= 8000.0) || sr > 192000.0) sr = 44100.0;   // 采样率非法就用 44100
    double w0 = 2.0 * M_PI * f0 / sr;
    double alpha = sin(w0) / (2.0 * Q);
    double a0 = 1.0 + alpha;
    q->b0 =  alpha / a0;
    q->b1 =  0.0;
    q->b2 = -alpha / a0;
    q->a1 = (-2.0 * cos(w0)) / a0;
    q->a2 = (1.0 - alpha) / a0;
    q->x1 = q->x2 = q->y1 = q->y2 = 0.0;
}

static void bands_init(double sr) {
    static const double centers[AXS_BANDS] = {31,62,125,250,500,1000,2000,4000,8000,16000};
    for (int i = 0; i < AXS_BANDS; i++) bq_bandpass(&gF[i], centers[i], 1.2, sr);
    for (int i = 0; i < AXS_BANDS; i++) {
        if (!isfinite(gF[i].b0) || !isfinite(gF[i].b2) || !isfinite(gF[i].a1) || !isfinite(gF[i].a2)) {
            for (int j = 0; j < AXS_BANDS; j++) bq_bandpass(&gF[j], centers[j], 1.2, 44100.0);
            break;
        }
    }
}

static inline double bq_run(Biquad *q, double x) {
    double y = q->b0*x + q->b1*q->x1 + q->b2*q->x2 - q->a1*q->y1 - q->a2*q->y2;
    if (!isfinite(y)) {   // 一旦出现 NaN/Inf，清空这段的滤波状态，别让污染扩散
        q->x1 = q->x2 = q->y1 = q->y2 = 0.0;
        y = 0.0;
    }
    q->x2 = q->x1; q->x1 = x;
    q->y2 = q->y1; q->y1 = y;
    return y;
}

// 归一化 float 单声道 → 10 段电平（-40..-2 dB → 0..100）
static void feed(float *p, int n) {
    if (n <= 0) return;
    double acc[AXS_BANDS];
    for (int i = 0; i < AXS_BANDS; i++) acc[i] = 0.0;
    for (int k = 0; k < n; k++) {
        double x = (double)p[k];
        if (!isfinite(x)) x = 0.0;
        for (int i = 0; i < AXS_BANDS; i++) {
            double y = bq_run(&gF[i], x);
            acc[i] += y * y;
        }
    }
    pthread_mutex_lock(&gLock);
    for (int i = 0; i < AXS_BANDS; i++) {
        double e  = sqrt(acc[i] / (double)n);
        double db = 20.0 * log10(e + 1e-9);
        double span = (double)gDbHi - (double)gDbLo;
        if (!(span > 5.0)) span = 38.0;              // 量程非法就退回默认跨度
        double v  = (db - gDbLo) / span * 100.0;
        if (!isfinite(v)) v = 0.0;
        if (v < 0) v = 0; if (v > 100) v = 100;
        double prev = gBand[i];
        if (!isfinite(prev)) prev = 0.0;
        gBand[i] = (v > prev) ? (prev*0.45 + v*0.55) : (prev*0.82 + v*0.18);
    }
    pthread_mutex_unlock(&gLock);
}

// ---------------------------------------------------------------- 钩子
typedef OSStatus (*RenderFn)(AudioUnit, AudioUnitRenderActionFlags *, const AudioTimeStamp *,
                             UInt32, UInt32, AudioBufferList *);
typedef void (*HookFn)(void *, void *, void **);

static RenderFn gOrigRender = NULL;

static void feed_from(void *data, UInt32 frames, UInt32 ch, int bits, int isFloat) {
    static float mono[1024];
    UInt32 n = frames > 1024 ? 1024 : frames;
    if (!data || ch == 0 || n == 0) return;

    if (isFloat && bits == 32) {
        float *src = (float *)data;
        UInt32 bad = 0;
        for (UInt32 i = 0; i < n; i++) {
            float v = src[i * ch];
            if (!isfinite(v)) { v = 0.0f; bad++; }
            mono[i] = v;
        }
        // 一半以上都不是有限浮点，说明格式判错了（缓冲其实是 16bit 整数），当场改判
        if (bad * 2 > n) {
            int16_t *s16 = (int16_t *)data;
            for (UInt32 i = 0; i < n; i++) mono[i] = (float)(s16[i * (ch ? ch : 1)] / 32768.0);
            gFmtFloat = 0; gFmtBits = 16;
        }
    } else if (!isFloat && bits == 16) {
        int16_t *src = (int16_t *)data;
        for (UInt32 i = 0; i < n; i++) mono[i] = (float)(src[i * ch] / 32768.0);
    } else if (!isFloat && bits == 32) {
        int32_t *src = (int32_t *)data;
        for (UInt32 i = 0; i < n; i++) mono[i] = (float)(src[i * ch] / 2147483648.0);
    } else {
        return;
    }
    feed(mono, (int)n);
}

static OSStatus hookedRender(AudioUnit au, AudioUnitRenderActionFlags *fl, const AudioTimeStamp *ts,
                             UInt32 bus, UInt32 frames, AudioBufferList *io) {
    OSStatus st = gOrigRender(au, fl, ts, bus, frames, io);
    if (st != noErr || !io || io->mNumberBuffers == 0) return st;

    if (!gFmtReady) {
        AudioStreamBasicDescription asbd;
        UInt32 sz = sizeof asbd;
        if (AudioUnitGetProperty(au, kAudioUnitProperty_StreamFormat,
                                 kAudioUnitScope_Output, bus, &asbd, &sz) == noErr && asbd.mSampleRate > 8000) {
            gFmtBits    = asbd.mBitsPerChannel ? (int)asbd.mBitsPerChannel : 32;
            gFmtFloat   = (asbd.mFormatFlags & kAudioFormatFlagIsFloat) ? 1 : 0;
            gFmtCh      = asbd.mChannelsPerFrame ? (int)asbd.mChannelsPerFrame : 1;
            gSampleRate = asbd.mSampleRate;
        } else {
            gFmtBits = 32; gFmtFloat = 1;
            gFmtCh = io->mBuffers[0].mNumberChannels ? (int)io->mBuffers[0].mNumberChannels : 1;
        }
        bands_init(gSampleRate);
        gFmtReady = 1;
    }

    AudioBuffer *b = &io->mBuffers[0];
    if (b->mData && frames > 0) {
        gCalls++;
        gFrames += frames;
        feed_from(b->mData, frames, (UInt32)gFmtCh, gFmtBits, gFmtFloat);
    }
    return st;
}

// ---------------------------------------------------------------- TCP + 文件输出
static int gListenFD = -1;

static void *srv_thread(void *arg) {
    (void)arg;
    mkdir(AXS_TMP, 0777);

    gListenFD = socket(AF_INET, SOCK_STREAM, 0);
    if (gListenFD < 0) return NULL;
    int one = 1;
    setsockopt(gListenFD, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
    struct sockaddr_in ad; memset(&ad, 0, sizeof ad);
    ad.sin_family = AF_INET;
    ad.sin_port   = htons(AXS_PORT);
    ad.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (bind(gListenFD, (struct sockaddr *)&ad, sizeof ad) < 0) { close(gListenFD); gListenFD = -1; return NULL; }
    if (listen(gListenFD, 4) < 0) { close(gListenFD); gListenFD = -1; return NULL; }
    fcntl(gListenFD, F_SETFL, O_NONBLOCK);
    gSrvOK = 1;

    int clients[4] = {-1,-1,-1,-1};
    char line[192];
    while (1) {
        int c = accept(gListenFD, NULL, NULL);
        if (c >= 0) for (int i = 0; i < 4; i++) if (clients[i] < 0) { clients[i] = c; break; }

        pthread_mutex_lock(&gLock);
        for (int i = 0; i < AXS_BANDS; i++) if (!isfinite(gBand[i])) gBand[i] = 0.0;
        int n = snprintf(line, sizeof line,
            "AXS %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f\n",
            gBand[0],gBand[1],gBand[2],gBand[3],gBand[4],
            gBand[5],gBand[6],gBand[7],gBand[8],gBand[9]);
        pthread_mutex_unlock(&gLock);

        for (int i = 0; i < 4; i++) {
            if (clients[i] < 0) continue;
            if (send(clients[i], line, n, MSG_NOSIGNAL) <= 0) { close(clients[i]); clients[i] = -1; }
        }

        static int tick = 0;
        if ((tick++ % 30) == 0) {
            FILE *rf = fopen(AXS_TMP "/range.txt", "r");
            if (rf) {
                double lo, hi;
                if (fscanf(rf, "%lf %lf", &lo, &hi) == 2 && hi > lo + 5) { gDbLo = lo; gDbHi = hi; }
                fclose(rf);
            }
        }

        FILE *f = fopen(AXS_LEVELS ".tmp", "w");
        if (f) { fputs(line, f); fclose(f); rename(AXS_LEVELS ".tmp", AXS_LEVELS); gWriteOK = 1; }
        usleep(33000);
    }
    return NULL;
}

// ---------------------------------------------------------------- 安装
static void *resolve(const char *names[], const char *sym) {
    void *p = dlsym(RTLD_DEFAULT, sym);
    if (p) return p;
    for (int i = 0; names[i]; i++) {
        void *h = dlopen(names[i], RTLD_NOW);
        if (h) { void *s = dlsym(h, sym); if (s) return s; }
    }
    return NULL;
}

__attribute__((visibility("default"))) int axs_start(void) {
    if (gHookOK) return 0;

    static const char *substrates[] = {
        "/var/jb/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate",
        "/var/jb/usr/lib/libellekit.dylib",
        "/var/jb/usr/lib/libsubstrate.dylib",
        "/usr/lib/libsubstrate.dylib",
        NULL
    };
    HookFn hook = (HookFn)resolve(substrates, "MSHookFunction");
    if (!hook) return -10;

    void *au = dlopen("/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox", RTLD_NOW);
    void *sym = au ? dlsym(au, "AudioUnitRender") : NULL;
    if (!sym) sym = dlsym(RTLD_DEFAULT, "AudioUnitRender");
    if (!sym) return -11;

    hook(sym, (void *)hookedRender, (void **)&gOrigRender);
    if (!gOrigRender) return -12;
    gHookOK = 1;

    pthread_t t;
    if (pthread_create(&t, NULL, srv_thread, NULL) == 0) pthread_detach(t);
    return 1;
}

__attribute__((visibility("default"))) int axs_stop(void) { gHookOK = 0; return 0; }
