#!/usr/bin/env python3
"""Free, offline 15-minute OneLife GitHub Actions continuation.

Select at most one verified, not-yet-rendered illustrated mascot clip per run,
import it with the existing Glossy V2 renderer, refresh QA, and publish a truthful
next-task handoff. This is a deterministic worker, NOT an LLM or image generator.
It never invents source artwork, modifies permissions, or touches user data.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "assets/characters-v2/animation_sources.json"
CHARACTERS = ("cat", "dog", "robot", "sprout")
STATES = ("idle", "remind", "alarm", "happy", "overloaded", "resting",
          "sleepy", "recovering", "focus", "study", "done", "thinking",
          "sad", "balanced", "strained")
# Finish the user-prioritized Cat art pack before starting dog, robot or sprout.
PRIORITY = [("cat", s) for s in ("done", "thinking", "sad", "balanced", "strained")]
PRIORITY += [(c, s) for c in CHARACTERS for s in STATES if (c, s) not in PRIORITY]
LABELS = {
    "idle": "Bình thường", "remind": "Nhắc việc", "alarm": "Báo thức",
    "happy": "Vui vẻ", "overloaded": "Quá tải minh họa", "resting": "Nghỉ ngơi",
    "sleepy": "Buồn ngủ", "recovering": "Tỉnh táo trở lại", "focus": "Tập trung",
    "study": "Học tập", "done": "Hoàn thành", "thinking": "Suy nghĩ",
    "sad": "Buồn", "balanced": "Cân bằng", "strained": "Hơi mệt",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_catalog(root: Path) -> dict[tuple[str, str], dict]:
    data = json.loads((root / "assets/characters-v2/animation_sources.json").read_text(encoding="utf-8"))
    registry: dict[tuple[str, str], dict] = {}
    for spec in data["animationSources"]:
        name, state = spec["characterId"], spec["state"]
        key = (name, state)
        if name not in CHARACTERS or state not in STATES or key in registry:
            raise ValueError(f"Unknown or duplicate clip: {key}")
        if spec.get("sourceFile") != "sheet_illustrated.webp":
            raise ValueError(f"Unexpected source filename: {key}")
        digest = spec["sourceSha256"]
        if not re.fullmatch(r"[0-9a-f]{64}", digest):
            raise ValueError(f"Invalid SHA-256: {key}")
        source = root / "assets/characters-v2" / name / state / spec["sourceFile"]
        if not source.is_file() or sha(source) != digest:
            raise ValueError(f"Absent or changed source art: {key}")
        registry[key] = spec
    return registry


def needs_render(root: Path, key: tuple[str, str], spec: dict) -> bool:
    name, state = key
    folder = root / "assets/characters-v2" / name / state
    required = [folder / p for p in ("sheet.png", "preview.gif", "metadata.json", "qa_report.json")]
    if not all(p.is_file() for p in required):
        return True
    try:
        meta = json.loads((folder / "metadata.json").read_text(encoding="utf-8"))
        return any((
            meta.get("characterId") != name, meta.get("state") != state,
            meta.get("sourceSha256") != spec["sourceSha256"],
            meta.get("sha256") != sha(folder / "sheet.png"),
            meta.get("frames") != spec["frames"],
            meta.get("frameDurationMs") != spec["frameDurationMs"],
            meta.get("loop") != spec["loop"],
        ))
    except (OSError, ValueError, KeyError):
        return True


def sync_cat_gallery(root: Path) -> bool:
    path = root / "design/review/glossy-cat-idle.html"
    source = path.read_text(encoding="utf-8")
    manifest = json.loads((root / "assets/characters-v2/cat/manifest.json").read_text(encoding="utf-8"))
    states = [s for s in STATES if s in manifest.get("states", {})]
    if not states:
        raise ValueError("Cat has no animation states")
    options = ''.join(f'<option value="{s}">{s.title()} · {escape(LABELS[s])}</option>' for s in states)
    option_rx = r'(<select id="state">)[\s\S]*?(</select>)'
    replacement = lambda m: m.group(1) + options + m.group(2)
    newer, count = re.subn(option_rx, replacement, source, count=1)
    if count != 1:
        raise ValueError("Cannot update Cat gallery state dropdown")
    configs = []
    for s in states:
        meta_path = root / "assets/characters-v2/cat" / s / "metadata.json"
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        configs.append(f'{s}:{{frames:{meta["frames"]},duration:{meta["frameDurationMs"]},loop:{str(meta["loop"]).lower()}}}')
    config_rx = r'const config=\{[\s\S]*?\};'
    newer, count = re.subn(config_rx, lambda _: 'const config={' + ','.join(configs) + '};', newer, count=1)
    if count != 1:
        raise ValueError("Cannot update Cat gallery playback configuration")
    intro = (f'<p class="muted">{len(states)} trạng thái Mèo Glossy V2 có sprite PNG nguồn thật. '
             'Trình xem chỉ phục vụ QA; chưa phải ứng dụng Flutter, chưa nghiệm thu trên điện thoại.</p>')
    newer, count = re.subn(r'<p class="muted">Xem các frame[\s\S]*?</p>', lambda _: intro, newer, count=1)
    if count != 1:
        raise ValueError("Cannot update Cat gallery introduction")
    if newer != source:
        path.write_text(newer, encoding="utf-8")
        return True
    return False


def update_next_task(root: Path, registry: dict[tuple[str, str], dict], blocked: list[tuple[str, str]]) -> tuple[str, str] | None:
    remaining = [key for key in PRIORITY if key not in registry]
    next_key = remaining[0] if remaining else None
    lines = [
        '# OneLife – Next actionable mascot task', '',
        '**Generated by deterministic GitHub Actions checks. This is not autonomous AI artwork generation.**', '',
        f'- Sourced illustration clips: **{len(registry)}/60**.',
        f'- Remaining illustration sources: **{60-len(registry)}**.',
        '- Current gate: **no user/device art approval recorded**.',
        '',
    ]
    if blocked:
        lines += [f'- Source exists, awaiting safe import: **{blocked[0][0]}/{blocked[0][1]}**.',
                  '- The 15-minute worker will import one valid source per run.', '']
    if next_key:
        name, state = next_key
        lines += [f'## Next original-art task: {name}/{state}', '',
                  f'- Character master: `assets/characters-v2/{name}/master.png`.',
                  f'- Create **8–12 genuinely distinct illustrated poses** for `{state}` in Glossy Kawaii V2, transparent 256×256 cells, 4 columns.',
                  '- Preserve character identity, real movement, no labels or poster grids.',
                  f'- Commit the source at `assets/characters-v2/{name}/{state}/sheet_illustrated.webp`.',
                  '- Add its true SHA-256, number of frames, interval, loop and provenance to `assets/characters-v2/animation_sources.json`.',
                  '- The next scheduled worker run can produce PNG/GIF/metadata and update the review automatically.',
                  '- **Missing source is a blocker**: this workflow cannot draw missing artwork or write creative code by itself.', '']
    else:
        lines += ['## Original-art source backlog is empty', '',
                  'All 60 source entries are registered; still complete human art review and device testing.', '']
    path = root / 'docs/NEXT_AUTO_TASK.md'
    output = '\n'.join(lines)
    if not path.is_file() or path.read_text(encoding='utf-8') != output:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(output, encoding='utf-8')
    return next_key


def run_command(*args: str) -> None:
    subprocess.run([sys.executable, str(ROOT / 'tools' / args[0]), *args[1:]], cwd=ROOT, check=True)


def run() -> None:
    registry = check_catalog(ROOT)
    blocked = [k for k in registry if needs_render(ROOT, k, registry[k])]
    # Critical: at most ONE real state import per scheduled tick.
    chosen = blocked[0] if blocked else None
    if chosen:
        from render_glossy_character_animation import build
        build(*chosen, registry[chosen])
        print(f'IMPORTED {chosen[0]}/{chosen[1]} on this run')
    changed_gallery = sync_cat_gallery(ROOT)
    run_command('check_mascot_coverage.py')
    if chosen or not (ROOT / 'design/review/cat-glossy-v2-contact.png').is_file():
        run_command('render_cat_glossy_contact.py')
    run_command('check_cat_glossy_review.py')
    remaining = [k for k in registry if needs_render(ROOT, k, registry[k])]
    next_key = update_next_task(ROOT, registry, remaining)
    status = (f'Imported: {"/".join(chosen) if chosen else "nothing pending"}; '
              f'catalog: {len(registry)}/60; next missing source: '
              f'{"/".join(next_key) if next_key else "none"}; '
              f'gallery updated: {changed_gallery}; human art QA: pending')
    print(status)
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a', encoding='utf-8') as f:
            f.write('## OneLife 15-minute auto-progress\n\n' + status + '\n\n')
            f.write('This runner cannot autonomously create original animation art or Flutter application logic.\n')


def self_test() -> None:
    with tempfile.TemporaryDirectory(prefix='onelife_autopilot_') as folder:
        root = Path(folder)
        (root / 'assets/characters-v2/cat/idle').mkdir(parents=True)
        src = root / 'assets/characters-v2/cat/idle/sheet_illustrated.webp'
        src.write_bytes(b'original-source-stub')
        (root / 'assets/characters-v2/animation_sources.json').write_text(json.dumps({
            'version':'1.0', 'animationSources':[{
                'characterId':'cat', 'state':'idle', 'sourceFile':'sheet_illustrated.webp',
                'sourceSha256':sha(src), 'frames':8, 'frameDurationMs':150, 'loop':True,
            }]}))
        entries = check_catalog(root)
        assert len(entries)==1 and needs_render(root, ('cat','idle'),entries[('cat','idle')])
        next_key = update_next_task(root,entries,[('cat','idle')])
        assert next_key==('cat','done')
        before=(root/'docs/NEXT_AUTO_TASK.md').read_bytes()
        update_next_task(root, entries, [('cat','idle')])
        assert (root/'docs/NEXT_AUTO_TASK.md').read_bytes()==before
        src.write_bytes(b'tampered')
        try:
            check_catalog(root)
        except ValueError as exc:
            assert 'changed source' in str(exc)
        else:
            raise AssertionError('Tampered source was not rejected')
    print('PASS autopilot selftest: candidate selection, next task, no-op determinism, SHA integrity')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        self_test()
    else:
        run()