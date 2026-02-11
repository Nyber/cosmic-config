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

                subtitle = req.get("subt", "")

                notifications.append({
                    "id": row["rec_id"],
                    "app": app,
                    "bundle_id": bundle_id,
                    "title": title,
                    "subtitle": subtitle,
                    "body": body,
                })
            except Exception:
                continue

        conn.close()
        return notifications

    except Exception:
        return []


def get_notification_info(rec_id):
    """Read notification data before dismissing."""
    try:
        conn = sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
        cur = conn.cursor()
        cur.execute(
            """
            SELECT r.data, a.identifier
            FROM record r JOIN app a ON r.app_id = a.app_id
            WHERE r.rec_id = ?
            """,
            (int(rec_id),),
        )
        row = cur.fetchone()
        conn.close()
        if row:
            plist = plistlib.loads(row[0])
            req = plist.get("req", {})
            return {
                "bundle_id": row[1],
                "title": req.get("titl", ""),
                "subtitle": req.get("subt", ""),
                "body": req.get("body", ""),
            }
    except Exception:
        pass
    return None


def mark_mail_as_read(info):
    """Mark matching Mail message as read via AppleScript."""
    sender = info.get("title", "")
    subject = info.get("subtitle", "") or info.get("body", "")
    if not sender and not subject:
        return
    # Escape for AppleScript string literals
    sender_esc = sender.replace("\\", "\\\\").replace('"', '\\"')
    subject_esc = subject.replace("\\", "\\\\").replace('"', '\\"')
    script = (
        'tell application "Mail"\n'
        "    set msgs to (every message of inbox whose "
        f'sender contains "{sender_esc}" and '
        f'subject contains "{subject_esc}" and '
        "read status is false)\n"
        "    repeat with m in msgs\n"
        "        set read status of m to true\n"
        "    end repeat\n"
        "end tell"
    )
    try:
        subprocess.run(["osascript", "-e", script], capture_output=True, timeout=5)
    except Exception:
        pass


def dismiss(target):
    # Mark as read in source app before deleting from DB
    if target != "all":
        info = get_notification_info(target)
        if info and info["bundle_id"] == "com.apple.mail":
            mark_mail_as_read(info)
    else:
        for notif in list_notifications():
            if notif["bundle_id"] == "com.apple.mail":
                mark_mail_as_read(notif)

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
        try:
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
        except Exception:
            interval = MAX_INTERVAL

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
