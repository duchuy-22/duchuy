ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

THEOS_DEVICE_IP =

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FPSOverlay
FPSOverlay_FILES = make.dylib.m
FPSOverlay_CFLAGS = -fobjc-arc
FPSOverlay_FRAMEWORKS = UIKit CoreGraphics QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
