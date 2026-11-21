/* axs_lv.c — 设备上读取真实电平的命令行小工具（可选自测）
 * 编译（越狱机上或交叉编译）：clang -target arm64-apple-ios15 -O2 -o axs_lv axs_lv.c
 * 签名：ldid -Sent.plist axs_lv   （需要 platform-application 权限，否则 zsh: killed）
 * 用法：./axs_lv         连续打印 20 行
 */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define PORT 47923
int main(void) {
    int s = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in a; memset(&a, 0, sizeof a);
    a.sin_family = AF_INET; a.sin_port = htons(PORT);
    a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (connect(s, (struct sockaddr *)&a, sizeof a) < 0) { printf("connect 127.0.0.1:%d 失败\n", PORT); return 1; }
    char buf[512]; int n = 0;
    while (n++ < 20) {
        ssize_t r = recv(s, buf, sizeof(buf) - 1, 0);
        if (r <= 0) break;
        buf[r] = 0; printf("%s", buf);
    }
    close(s);
    return 0;
}
