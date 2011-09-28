include theos/makefiles/common.mk
GO_EASY_ON_ME=1
TWEAK_NAME = ProcessBadge
ProcessBadge_FILES = Tweak.xm
ProcessBadge_FRAMEWORKS = UIKit QuartzCore
include $(THEOS_MAKE_PATH)/tweak.mk

