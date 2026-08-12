ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:15.0
CFLAGS += -fno-modules
INSTALL_TARGET_PROCESSES = SpringBoard

# Rootless 配置 (NathanLR / ElleKit)
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

# 子工程
SUBPROJECTS += CCWeatherModule
SUBPROJECTS += CCWeatherTweak
SUBPROJECTS += CCWeatherPrefs

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
