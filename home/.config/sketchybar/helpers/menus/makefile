bin/menus: menus.c | bin
	clang -std=c99 -O3 -Wall -Wextra -Wno-deprecated-declarations -F/System/Library/PrivateFrameworks/ -framework Carbon -framework SkyLight $< -o $@

bin:
	mkdir bin
