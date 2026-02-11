#!/usr/bin/python3
"""Read/dismiss macOS notification center DB entries for SketchyBar.

Usage:
  notification_reader.py              # list notifications (JSON to stdout + cache)
  notification_reader.py dismiss ID   # dismiss notification by rec_id
  notification_reader.py dismiss all  # dismiss all notifications
  notification_reader.py watch        # watch WAL via kqueue, update cache on change
"""
import json
import os
import plistlib
import pwd
import sqlite3
import subprocess
import sys
import time

_user_home = pwd.getpwuid(os.getuid()).pw_dir
DB_PATH = os.path.join(
    _user_home, "Library/Group Containers/group.com.apple.usernoted/db2/db"
)
CACHE_DIR = os.path.dirname(os.path.abspath(__file__))

# Map bundle IDs to display names (must match app_icons.lua keys)
BUNDLE_NAMES = {
    "org.whispersystems.signal-desktop": "Signal",
    "us.zoom.xos": "zoom.us",
    "com.apple.MobileSMS": "Messages",
    "com.apple.mail": "Mail",
    "com.tinyspeck.slackmacgap": "Slack",
    "com.microsoft.teams2": "Microsoft Teams",
    "com.microsoft.Outlook": "Microsoft Outlook",
}


def app_name_from_bundle(bundle_id):
    if bundle_id in BUNDLE_NAMES:
        return BUNDLE_NAMES[bundle_id]
    parts = bundle_id.rsplit(".", 1)
    return parts[-1] if parts else bundle_id


def list_notifications():
    if not os.path.exists(DB_PATH):
        return []

    try:
        conn = sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()

        cur.execute(
            """
            SELECT r.rec_id, r.data, a.identifier, r.delivered_date
            FROM record r
            JOIN app a ON r.app_id = a.app_id
            ORDER BY r.delivered_date DESC
            """
        )

        notifications = []
        for row in cur.fetchall():
            try:
                plist = plistlib.loads(row["data"])
                req = plist.get("req", {})
                title = req.get("titl", "")
                body = req.get("body", "")
                bundle_id = row["identifier"]
                app = app_name_from_bundle(bundle_id)

                notifications.append({
                    "id": row["rec_id"],
                    "app": app,
                    "bundle_id": bundle_id,
                    "title": title,
                    "body": body,
                })
            except Exception:
                continue

        conn.close()
        return notifications

    except Exception:
        return []


def dismiss(target):
    try:
        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()
        if target == "all":
            cur.execute("DELETE FROM record")
        else:
            cur.execute("DELETE FROM record WHERE rec_id = ?", (int(target),))
        conn.commit()
        conn.close()
    except Exception:
        pass


def write_cache(notifications):
    cache = os.path.join(CACHE_DIR, ".notif_cache.json")
    with open(cache, "w") as f:
        json.dump(notifications, f)


def watch():
    """Poll notification DB for changes and update cache + trigger SketchyBar."""
    MIN_INTERVAL = 2
    MAX_INTERVAL = 15
    interval = MIN_INTERVAL

    last_ids = set()

    while True:
        notifications = list_notifications()
        current_ids = {n["id"] for n in notifications}

        if current_ids != last_ids:
            last_ids = current_ids
            write_cache(notifications)
            subprocess.run(
                ["sketchybar", "--trigger", "wal_changed"], capture_output=True
            )
            interval = MIN_INTERVAL  # Reset to fast polling on change
        else:
            interval = min(interval + 1, MAX_INTERVAL)  # Back off when idle

        time.sleep(interval)


def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "watch":
        watch()
        return

    if len(sys.argv) >= 3 and sys.argv[1] == "dismiss":
        dismiss(sys.argv[2])
        # Refresh cache after dismiss
        notifications = list_notifications()
        write_cache(notifications)
        return

    notifications = list_notifications()
    json.dump(notifications, sys.stdout)
    write_cache(notifications)


if __name__ == "__main__":
    main()
