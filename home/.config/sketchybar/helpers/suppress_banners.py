#!/usr/bin/python3
"""Suppress native macOS notification banners for all apps.

Modifies the usernoted preferences plist to clear bit 29 (banner display)
in each app's flags bitmask, then restarts usernoted to apply changes.

Safe to re-run — idempotent. Apps that already have banners off are unchanged.
"""
import os
import plistlib
import pwd
import subprocess
import sys

_user_home = pwd.getpwuid(os.getuid()).pw_dir
PLIST_PATH = os.path.join(
    _user_home,
    "Library/Group Containers/group.com.apple.usernoted/"
    "Library/Preferences/group.com.apple.usernoted.plist",
)

BANNER_BIT = 1 << 29


def suppress_banners():
    if not os.path.exists(PLIST_PATH):
        print(f"Plist not found: {PLIST_PATH}", file=sys.stderr)
        return False

    with open(PLIST_PATH, "rb") as f:
        plist = plistlib.load(f)

    apps = plist.get("apps", {})
    changed = 0
    for bundle_id, app_prefs in apps.items():
        flags = app_prefs.get("flags", 0)
        if flags & BANNER_BIT:
            app_prefs["flags"] = flags & ~BANNER_BIT
            changed += 1

    if changed == 0:
        return True

    with open(PLIST_PATH, "wb") as f:
        plistlib.dump(plist, f)

    subprocess.run(["killall", "usernoted"], capture_output=True)
    return True


if __name__ == "__main__":
    suppress_banners()
