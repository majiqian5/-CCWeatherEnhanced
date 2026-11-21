//
//  AxsTcpLevels.m — 面板侧消费端：从 127.0.0.1:47923 读真实电平
//  用法：放进面板工程，在 pollLevels 开头调用：
//      float lv[10];
//      if (AxsTcpPollLevels(lv)) { /* 用 lv 画频谱 */ } else { /* 走旧的 fallback */ }
//
#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>

static int s_fd = -1;
static char s_acc[8192];      // 累积缓冲，处理半行

// 从累积缓冲里取最后一条完整行并解析，返回 YES/NO
static BOOL parseLatest(float out[10]) {
    char *lastNL = strrchr(s_acc, '\n');
    if (!lastNL) return NO;
    char *lineStart = NULL;
    for (char *p = lastNL; p >= s_acc; p--) {
        if (*p == '\n') { lineStart = p + 1; break; }
    }
    if (!lineStart) return NO;

    char *start = strrchr(s_acc, '\n');
    // 找到倒数第二个换行，保证取的是"最后一条完成的行"
    char *prev = NULL;
    for (char *p = s_acc; p < lastNL; p++) if (*p == '\n') prev = p;
    start = prev ? prev + 1 : s_acc;

    if (strncmp(start, "AXS", 3) != 0) { strcpy(s_acc, ""); return NO; }
    float v[10];
    int got = sscanf(start + 3, "%f %f %f %f %f %f %f %f %f %f",
                     &v[0],&v[1],&v[2],&v[3],&v[4],&v[5],&v[6],&v[7],&v[8],&v[9]);
    // 只保留最后一行，避免缓冲越来越长
    strcpy(s_acc, lastNL + 1);
    if (got != 10) return NO;
    for (int i = 0; i < 10; i++) out[i] = v[i];
    return YES;
}

// 非阻塞，随时可调；返回 YES 时 out 为 0..100 的 10 段电平
BOOL AxsTcpPollLevels(float out[10]) {
    if (s_fd < 0) {
        int fd = socket(AF_INET, SOCK_STREAM, 0);
        if (fd < 0) return NO;
        struct sockaddr_in a; memset(&a, 0, sizeof a);
        a.sin_family = AF_INET;
        a.sin_port   = htons(47923);
        a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        if (connect(fd, (struct sockaddr *)&a, sizeof a) < 0) { close(fd); return NO; }
        fcntl(fd, F_SETFL, O_NONBLOCK);
        s_fd = fd;
    }
    char buf[2048];
    for (;;) {
        ssize_t r = recv(s_fd, buf, sizeof(buf) - 1, 0);
        if (r > 0) {
            buf[r] = 0;
            size_t have = strlen(s_acc), add = (size_t)r;
            if (have + add >= sizeof(s_acc) - 1) { strcpy(s_acc, ""); have = 0; }
            memcpy(s_acc + have, buf, add);
            s_acc[have + add] = 0;
            continue;                     // 尽量把内核缓冲读空
        }
        if (r < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) break;
        if (r < 0) { close(s_fd); s_fd = -1; return NO; }
        break;                            // r == 0：对端关闭
    }
    return parseLatest(out);
}
