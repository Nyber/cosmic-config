bin/volume: volume.c | bin
	clang -std=c99 -O3 -Wall -Wextra -framework CoreAudio -framework AudioToolbox $< -o $@

bin:
	mkdir bin
