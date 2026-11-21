// AxsAutoLoad.m — 注入 SpringBoard，仅在启动完成很久之后才触发一次注入
// 设计原则：不在任何系统进程的启动早期做危险动作，所有工作都丢给独立后台进程。
#import <Foundation/Foundation.h>
#include <spawn.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>

extern char **environ;

static const char *kStateDir = "/var/mobile/Library/AxsEQ";

static void axs_mark(const char *name, const char *text) {
    char path[256];
    snprintf(path, sizeof path, "%s/%s", kStateDir, name);
    FILE *f = fopen(path, "a");
    if (f) {
        time_t t = time(NULL);
        struct tm tmv;
        localtime_r(&t, &tmv);
        fprintf(f, "%04d-%02d-%02d %02d:%02d:%02d %s\n",
                tmv.tm_year + 1900, tmv.tm_mon + 1, tmv.tm_mday,
                tmv.tm_hour, tmv.tm_min, tmv.tm_sec, text);
        fclose(f);
    }
}

static const char *axs_sh(void) {
    // rootless 下 /bin/sh 可能不可用，优先用 /var/jb 里的
    return (access("/var/jb/usr/bin/sh", X_OK) == 0) ? "/var/jb/usr/bin/sh" : "/bin/sh";
}

__attribute__((constructor))
static void axs_autoload_init(void) {
    mkdir(kStateDir, 0755);
    axs_mark("tweak.log", "SpringBoard loaded AxsAutoLoad");

    const char *sh = axs_sh();
    char *argv[] = { (char *)sh, (char *)"/var/jb/usr/bin/axs_boot.sh", NULL };

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETSID);   // 脱离 SpringBoard 会话，注销也不受影响
    pid_t pid = 0;
    int rc = posix_spawn(&pid, sh, NULL, &attr, argv, environ);
    posix_spawnattr_destroy(&attr);

    if (rc == 0) {
        char buf[128];
        snprintf(buf, sizeof buf, "spawned boot script pid=%d", (int)pid);
        axs_mark("tweak.log", buf);
    } else {
        char buf[128];
        snprintf(buf, sizeof buf, "spawn failed rc=%d", rc);
        axs_mark("tweak.log", buf);
    }
}
