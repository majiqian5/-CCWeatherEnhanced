# Theos 构建（Linux/macOS 均可；注意 Linux 工具链编出的 arm64e 无 PAC，钩子会崩）
TARGET := iphone:clang:16.4:15.0
ARCHS  := arm64e
INSTALL_TARGET_PROCESSES := mediaserverd

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = AxsLevel
AxsLevel_FILES = AxsLevel.m
AxsLevel_FRAMEWORKS = Foundation AudioToolbox
AxsLevel_CFLAGS = -fobjc-arc -O2
AxsLevel_INSTALL_PATH = /Library/AxsEQ

include $(THEOS_MAKE_PATH)/library.mk
