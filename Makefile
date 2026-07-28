export THEOS=/opt/theos
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MenuESP
MenuESP_FILES = Tweak.xm
MenuESP_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
MenuESP_LDFLAGS += -framework UIKit -framework Foundation -framework OpenGLES

include $(THEOS)/makefiles/tweak.mk

after-install::
	install.exec "killall -9 FreeFire"
