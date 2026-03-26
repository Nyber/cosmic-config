FONT := $(HOME)/Library/Fonts/sketchybar-app-font.ttf

all: icon_set.lua
	(cd menus && $(MAKE)) >/dev/null
	(cd badges && $(MAKE)) >/dev/null
	(cd volume && $(MAKE)) >/dev/null

icon_set.lua: $(FONT) extract_icon_set.py
	@python3 extract_icon_set.py 2>/dev/null || true
