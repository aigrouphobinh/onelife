#!/usr/bin/env python3
"""Guard OneLife usage-aware Brain against silent tracking and fake metrics."""
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NAME = "{http://schemas.android.com/apk/res/android}name"
manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
usage = ROOT / "android/app/src/main/kotlin/com/aigrouphobinh/onelife/UsageInsights.kt"
main = ROOT / "android/app/src/main/kotlin/com/aigrouphobinh/onelife/MainActivity.kt"
overlay = ROOT / "android/app/src/main/kotlin/com/aigrouphobinh/onelife/BrainOverlayService.kt"
flutter = ROOT / "lib/src/phone_usage_page.dart"


def main_check() -> None:
    tree = ET.parse(manifest)
    permissions = {item.attrib[NAME] for item in tree.findall("uses-permission")}
    assert "android.permission.PACKAGE_USAGE_STATS" in permissions
    assert "android.permission.QUERY_ALL_PACKAGES" not in permissions

    raw = usage.read_text(encoding="utf-8")
    activity = main.read_text(encoding="utf-8")
    native_overlay = overlay.read_text(encoding="utf-8")
    page = flutter.read_text(encoding="utf-8")

    assert "AppOpsManager.OPSTR_GET_USAGE_STATS" in raw
    assert "AppOpsManager.MODE_ALLOWED" in raw
    assert "queryEvents(startOfToday, end)" in raw
    assert "UsageEvents.Event.MOVE_TO_FOREGROUND" in raw
    assert "UsageEvents.Event.MOVE_TO_BACKGROUND" in raw
    assert "if (!observed) return unknown(" in raw
    assert '"minutes" to null' in raw
    assert 'minutes >= THREE_HOURS -> "high"' in raw
    assert 'minutes >= NINETY_MINUTES -> "break"' in raw
    assert "NINETY_MINUTES = 90L" in raw
    assert "THREE_HOURS = 180L" in raw
    assert "Build.VERSION_CODES.N" in raw
    assert '"usageSnapshot"' in activity
    assert '"openUsageAccessSettings"' in activity
    assert "Settings.ACTION_USAGE_ACCESS_SETTINGS" in activity
    assert "Thread {" in activity

    # Brain may be shown without Usage Access, but cannot read without it.
    assert "UsageInsights.snapshot(applicationContext)" in native_overlay
    assert '"unknown"' in native_overlay
    assert 'brain/focus/sheet.png' in native_overlay
    assert "5 * 60 * 1000L" in native_overlay
    assert "if (!observed)" in raw

    assert "Thiếu dữ liệu không có nghĩa" in page
    assert "Không lưu danh sách ứng dụng" in page
    assert "Mở Cài đặt quyền sử dụng" in page
    print("PASS: Brain Usage Access opt-in, no invented values, no per-app data export")


if __name__ == "__main__":
    main_check()
