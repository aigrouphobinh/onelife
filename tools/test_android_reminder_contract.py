#!/usr/bin/env python3
"""Verify the Android V3.4 reminder permissions and receiver safety contract."""
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"
NS = "{http://schemas.android.com/apk/res/android}"


def main() -> None:
    tree = ET.parse(MANIFEST)
    root = tree.getroot()
    permissions = {
        item.attrib[f"{NS}name"] for item in root.findall("uses-permission")
    }
    assert "android.permission.POST_NOTIFICATIONS" in permissions
    assert "android.permission.RECEIVE_BOOT_COMPLETED" in permissions
    assert "android.permission.SCHEDULE_EXACT_ALARM" not in permissions

    receivers = {
        item.attrib[f"{NS}name"]: item
        for item in root.findall("./application/receiver")
    }
    actions = receivers[".TaskReminderReceiver"]
    assert actions.attrib[f"{NS}exported"] == "false", actions.attrib
    boot = receivers[".TaskReminderRestoreReceiver"]
    assert boot.attrib[f"{NS}enabled"] == "false", boot.attrib
    assert boot.attrib[f"{NS}exported"] == "true", boot.attrib
    names = {
        node.attrib[f"{NS}name"]
        for node in boot.findall("./intent-filter/action")
    }
    assert "android.intent.action.BOOT_COMPLETED" in names

    scheduler = (
        ROOT / "android/app/src/main/kotlin/com/aigrouphobinh/onelife/TaskReminders.kt"
    ).read_text(encoding="utf-8")
    assert "setAndAllowWhileIdle(" in scheduler
    assert "setExactAndAllowWhileIdle(" not in scheduler
    assert 'private const val ENABLED = "enabled"' in scheduler

    receiver = (
        ROOT / "android/app/src/main/kotlin/com/aigrouphobinh/onelife/TaskReminderReceiver.kt"
    ).read_text(encoding="utf-8")
    assert 'setVisibility(Notification.VISIBILITY_PRIVATE)' in receiver
    assert 'setPublicVersion(publicVersion)' in receiver
    assert 'Hoàn thành' in receiver and 'Nhắc lại 10 phút' in receiver
    print("PASS: Android opt-in reminders, native actions, privacy and boot permissions")


if __name__ == "__main__":
    main()
