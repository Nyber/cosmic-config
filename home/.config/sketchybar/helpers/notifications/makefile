bin/notifications: notifications.swift | bin
	swiftc -O -framework Foundation -framework AppKit -lsqlite3 $< -o $@

bin:
	mkdir bin
