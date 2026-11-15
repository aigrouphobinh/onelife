#!/usr/bin/env python3
"""Validate opt-in Brain break contracts without pretending to run an Android UI.

The real workflow ALSO compiles Kotlin/Flutter and runs widget tests; device
behavior still requires separate physical QA.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "android/app/src/main/kotlin/com/aigrouphobinh/onelife"
FLUTTER = ROOT / "lib/src"
TEST = ROOT / "test/brain_break_page_test.dart"


def main():
    core = (NATIVE / "BrainBreaks.kt").read_text(encoding="utf-8")
    overlay = (NATIVE / "BrainOverlayService.kt").read_text(encoding="utf-8")
    activity = (NATIVE / "MainActivity.kt").read_text(encoding="utf-8")
    page = (FLUTTER / "brain_break_page.dart").read_text(encoding="utf-8")
    test = TEST.read_text(encoding="utf-8")

    for required in (
        "minutes !in listOf(5, 10, 15)",
        'getString(PHASE, "idle")',
        '"resting"',
        '"recovering"',
        'private const val RECOVERY_MS = 12L * 125L',
        'private const val MAX_LATE_MS = 3_000L',
        'if (now - deadline in 0L..MAX_LATE_MS)',
        'return state("idle", sequence)',
        'fun start(c: Context, minutes: Int',
        'fun finish(c: Context, now: Long',
        'fun cancel(c: Context)',
        '@Synchronized',
        '.commit()',
    ):
        assert required in core, ("Missing persisted break guard", required)

    for action in ('"breakSnapshot"', '"startBrainBreak"',
                   '"finishBrainBreak"', '"cancelBrainBreak"'):
        assert action in activity, action
        assert action.replace('"', "'") in page, action
    assert "refreshActiveBrainBreak()" in activity
    assert "if (!BrainOverlayService.isVisible || !overlayAllowed()) return" in activity

    for required in (
        'BrainBreaks.snapshot(applicationContext)',
        'BrainBreaks.start(this, 5)',
        'BrainBreaks.finish(this)',
        'phase == "resting"',
        'phase == "recovering"',
        '"resting" -> 205L',
        '"recovering" -> 125L',
        '"strained", "resting" -> 10',
        '"overloaded", "recovering" -> 12',
        'if (frameIndex < count - 1) frameIndex += 1',
        'focused && focusSheet != null',
        'handler.postDelayed(this, nextDelay)',
    ):
        assert required in overlay, ("Missing real overlay break integration", required)

    for required in (
        'loop: true',
        'loop: false',
        'frameDurationMs: 205',
        'frameDurationMs: 125',
        'Bắt đầu nghỉ ',
        'Kết thúc nghỉ',
        'Hủy phiên nghỉ',
        "AppLifecycleState.resumed",
        "remainingSeconds",
        "deadlineMs",
    ):
        assert required in page, required
    assert "iOS does not invoke Android break service" in test
    assert "cancelling rest never plays completion animation" in test
    assert "finishing an active rest" in test
    print("PASS: deliberate breaks, persisted deadlines, native Resting loop, one-shot Recovering")


if __name__ == "__main__":
    main()
