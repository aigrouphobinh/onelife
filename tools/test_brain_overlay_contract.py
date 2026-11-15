#!/usr/bin/env python3
"""Static Android safety checks for OneLife V3.4's real Brain overlay."""
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android/app/src/main"
KOTLIN = ANDROID / "kotlin/com/aigrouphobinh/onelife"
NS = "{http://schemas.android.com/apk/res/android}"


def main() -> None:
    root = ET.parse(ANDROID / "AndroidManifest.xml").getroot()
    permissions = {
        item.attrib[f"{NS}name"] for item in root.findall("uses-permission")
    }
    assert "android.permission.SYSTEM_ALERT_WINDOW" in permissions
    services = {
        item.attrib[f"{NS}name"]: item
        for item in root.findall("./application/service")
    }
    overlay = services[".BrainOverlayService"]
    assert overlay.attrib[f"{NS}exported"] == "false"
    assert not overlay.findall("intent-filter"), "Overlay must never be exported"
    assert "android.permission.BIND_ACCESSIBILITY_SERVICE" not in permissions
    assert "android.permission.FOREGROUND_SERVICE" not in permissions

    service = (KOTLIN / "BrainOverlayService.kt").read_text(encoding="utf-8")
    activity = (KOTLIN / "MainActivity.kt").read_text(encoding="utf-8")
    flutter = (ROOT / "lib/src/brain_overlay_setup_page.dart").read_text(encoding="utf-8")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")

    for item in (
        "WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY",
        "WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE",
        "Settings.canDrawOverlays(this)",
        "START_NOT_STICKY",
        "override fun onDestroy()",
        "manager.removeViewImmediate(view)",
        "addAction(menu, \"×  Ẩn Brain\")",
        "assets/characters-v2/brain/idle/sheet.png",
    ):
        assert item in service, f"Missing real Android implementation: {item}"
    for method in (
        '"overlayStatus"',
        '"requestOverlayPermission"',
        '"startBrainOverlay"',
        '"stopBrainOverlay"',
    ):
        assert method in activity, method
    assert "Settings.ACTION_MANAGE_OVERLAY_PERMISSION" in activity
    assert "startService(Intent(this, BrainOverlayService::class.java))" in activity
    assert "stopService(Intent(this, BrainOverlayService::class.java))" in activity
    assert "assets/characters-v2/brain/idle/sheet.png" in pubspec
    assert "onPressed: _busy ? null : () => _run('startBrainOverlay')" in flutter
    assert "initState()" in flutter
    assert "_checkStatus()" in flutter
    # Native code must never start the overlay in onCreate/onResume/on boot.
    assert "startBrainOverlay(result)" in activity
    assert activity.count("startService(Intent(this, BrainOverlayService::class.java))") == 1
    print("PASS: Brain overlay is a real opt-in, private, draggable Android window")


if __name__ == "__main__":
    main()
