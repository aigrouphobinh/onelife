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
    assert "queryEvents(start, end)" in raw
    assert "UsageEvents.Event.MOVE_TO_FOREGROUND" in raw
    assert "UsageEvents.Event.MOVE_TO_BACKGROUND" in raw
    assert "if (!observed) return unavailable(" in raw
    assert '"minutes" to null' in raw
    assert 'minutes >= goal -> "overloaded"' in raw
    assert 'minutes.toLong() * 5 >= goal.toLong() * 4 -> "strained"' in raw
    assert 'if (goal == null' in raw
    assert "fun saveGoal(context: Context, minutes: Int?): Boolean" in raw
    assert "GOAL = \"daily_reflection_goal_minutes\"" in raw
    assert "MIN_GOAL = 30" in raw and "MAX_GOAL = 720" in raw
    assert "Build.VERSION_CODES.N" in raw
    assert '"usageSnapshot"' in activity
    assert '"setUsageDailyGoal"' in activity
    assert '"openUsageAccessSettings"' in activity
    assert "Settings.ACTION_USAGE_ACCESS_SETTINGS" in activity
    assert "Thread {" in activity

    # Brain may be shown without Usage Access, but cannot read without it.
    assert "UsageInsights.snapshot(applicationContext)" in native_overlay
    assert '"unknown"' in native_overlay
    assert 'snapshot["goalMinutes"] !is Int' in native_overlay
    assert 'usageTier == "balanced"' in native_overlay
    assert 'private val focusSheet = decode("focus")' in native_overlay
    assert '"flutter_assets/assets/characters-v2/brain/"' in native_overlay
    assert "5 * 60 * 1000L" in native_overlay
    assert "if (!observed)" in raw

    assert "Thiếu dữ liệu không có nghĩa" in page
    assert "Không lưu danh sách ứng dụng" in page
    assert "Mở Cài đặt quyền sử dụng" in page
    assert "Mục tiêu phản ánh hằng ngày" in page
    assert "Tắt mục tiêu" in page
    print("PASS: Brain Usage Access, user goals, no default judgment or per-app data export")


if __name__ == "__main__":
    main_check()
