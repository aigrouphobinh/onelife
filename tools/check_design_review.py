#!/usr/bin/env python3
"""Static smoke checks for OneLife design-only HTML and its local dependencies."""
from html.parser import HTMLParser
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / "design/review/index.html"

class Tags(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = set()
        self.scripts = []
        self.in_script = False
        self.script_buf = []
        self.external_scripts = []
    def handle_starttag(self, tag, attrs):
        props = dict(attrs)
        if "id" in props:
            assert props["id"] not in self.ids, f"Duplicate id {props['id']}"
            self.ids.add(props["id"])
        if tag == "script":
            if props.get("src"): self.external_scripts.append(props["src"])
            self.in_script = True
            self.script_buf = []
    def handle_data(self, data):
        if self.in_script: self.script_buf.append(data)
    def handle_endtag(self, tag):
        if tag == "script":
            self.in_script = False
            if self.script_buf: self.scripts.append("".join(self.script_buf))

def main():
    html = HTML.read_text(encoding="utf-8")
    parsed = Tags()
    parsed.feed(html)
    assert not parsed.external_scripts, "External runtime scripts are not permitted"
    ids = ["character", "state", "size", "motion", "hero", "frameSeek",
           "frameLabel", "pause", "nextFrame", "animationInfo",
           "screen", "pages", "prevPage", "nextPage", "themeButton"]
    assert all(x in parsed.ids for x in ids), "Missing a design review interactive control"
    assert len(parsed.scripts) == 1, "Expected one self-contained JS script"
    script = parsed.scripts[0]
    result = subprocess.run(["node", "--check", "-"], input=script, text=True, capture_output=True)
    assert result.returncode == 0, "JavaScript parse failure:\n" + result.stderr
    assert not re.search(r"\bfetch\s*\(|\bXMLHttpRequest\b", script), "Design viewer must remain local/offline"
    char_ids = ("brain", "cat", "dog", "robot", "sprout")
    states = ("idle", "happy", "remind", "alarm", "focus", "study", "sleepy", "done", "thinking", "sad")
    for char in char_ids:
        assert (ROOT / "assets/characters" / char / "master.svg").is_file()
        for state in states:
            assert (ROOT / "assets/characters" / char / state / "sheet.png").is_file(), char + "/" + state
    for page in ("01-splash","02-onboarding","03-home","04-tasks","05-schedule",
                 "06-habits","07-assistant","08-characters","09-settings","10-overlay-android"):
        assert (ROOT / "design/screens" / (page + ".png")).is_file(), page
    assert (ROOT / "design/review/reports/asset-qa.md").is_file(), "Asset QA report must be committed first"
    print("PASS design preview: JS syntax, 50 local atlas paths, 10 design screens, controls")

if __name__ == "__main__":
    main()
