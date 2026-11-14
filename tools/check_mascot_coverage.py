#!/usr/bin/env python3
"""Audit the 60 desired non-Brain OneLife Glossy V2 animation clips.

Evidence-only: never converts a static master or a composed poster into a completed sprite.
Missing states are reported, not silently generated.
"""
from __future__ import annotations
import hashlib
import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/characters-v2'
REPORT = ROOT / 'design/review/reports/other-mascot-coverage.json'
MD = ROOT / 'docs/OTHER_MASCOT_COVERAGE.md'
CHARACTERS = ('cat', 'dog', 'robot', 'sprout')
STATES = ('idle', 'remind', 'alarm', 'happy', 'overloaded', 'resting',
          'sleepy', 'recovering', 'focus', 'study', 'done', 'thinking',
          'sad', 'balanced', 'strained')


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    problems = []
    all_rows = []
    counters = {'originalIllustratedCandidates': 0, 'derivedCandidates': 0, 'missing': 0}
    for char in CHARACTERS:
        base = SOURCE / char
        if not (base / 'master.png').is_file() or not (base / 'master.webp').is_file():
            problems.append(char + ': master files missing')
        for state in STATES:
            folder = base / state
            paths = {n: folder / n for n in ('metadata.json', 'sheet.png', 'preview.gif')}
            existing = {n for n, p in paths.items() if p.exists()}
            if not existing:
                row = {'characterId': char, 'state': state, 'status': 'missing'}
                counters['missing'] += 1
                all_rows.append(row)
                continue
            if len(existing) != len(paths):
                problems.append(f'{char}/{state}: partial asset set ({sorted(existing)})')
                all_rows.append({'characterId':char, 'state':state, 'status':'incomplete-invalid'})
                continue
            try:
                m = json.loads(paths['metadata.json'].read_text(encoding='utf-8'))
                n = int(m['frames'])
                cols = int(m['columns'])
                rows = int(m['rows'])
                if m['characterId'] != char or m['state'] != state:
                    raise ValueError('Character/state metadata mismatch')
                if not (8 <= n <= 24 and cols == 4 and rows == (n+3)//4):
                    raise ValueError('Frame count / atlas row geometry mismatch')
                if m.get('sha256') != digest(paths['sheet.png']):
                    raise ValueError('PNG checksum mismatch')
                with Image.open(paths['sheet.png']) as im:
                    if im.size != (int(m['frameWidth'])*cols, int(m['frameHeight'])*rows):
                        raise ValueError('PNG dimensions mismatch')
                with Image.open(paths['preview.gif']) as gif:
                    if getattr(gif, 'n_frames', 1) < 2:
                        raise ValueError('GIF not animated')
                source = folder / m.get('source', '')
                if not source.is_file():
                    raise ValueError('illustrated source missing')
                if m.get('sourceSha256') and digest(source) != m['sourceSha256']:
                    raise ValueError('source checksum mismatch')
                kind = m.get('generationClass','unspecified')
                if kind == 'independently-illustrated-pose-sheet':
                    counters['originalIllustratedCandidates'] += 1
                    status = 'original-candidate-qa'
                else:
                    counters['derivedCandidates'] += 1
                    status = 'derived-candidate-qa'
                row = {'characterId': char, 'state': state, 'status': status,
                       'frames':n, 'generationClass':kind,
                       'artReview':'pending', 'deviceReview':'pending'}
            except (OSError, ValueError, KeyError, TypeError) as e:
                row = {'characterId':char, 'state':state, 'status':'incomplete-invalid'}
                problems.append(f'{char}/{state}: {e}')
            all_rows.append(row)
    total = len(CHARACTERS)*len(STATES)
    available = counters['originalIllustratedCandidates']+counters['derivedCandidates']
    result = {'schemaVersion':1, 'totalRequiredClips':total,
              'illustratedCandidates':counters['originalIllustratedCandidates'],
              'derivedCandidates':counters['derivedCandidates'],
              'missing':counters['missing'], 'availableCandidates':available,
              'artApprovedCount':0, 'phoneVerifiedCount':0,
              'automatedEvidencePass':not problems, 'errors':problems, 'clips':all_rows}
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(result, indent=2, ensure_ascii=False)+'\n',encoding='utf-8')
    summary = [
        '# OneLife – Other Mascot Animation Coverage', '',
        '**This report measures files, NOT finished product quality.**', '',
        f'- Required: **{total}** clips = 4 characters × 15 states.',
        f'- Original illustrated candidates: **{counters["originalIllustratedCandidates"]}**.',
        f'- Derived-pose candidates (not independently illustrated): **{counters["derivedCandidates"]}**.',
        f'- Missing: **{counters["missing"]}**.',
        '- Art approved on mobile: **0** (not independently tested).',
        '', '| Character | Original | Derived | Missing |', '|---|---:|---:|---:|'
    ]
    for char in CHARACTERS:
        rows = [r for r in all_rows if r['characterId']==char]
        original = sum(r['status']=='original-candidate-qa' for r in rows)
        derived = sum(r['status']=='derived-candidate-qa' for r in rows)
        missing = sum(r['status']=='missing' for r in rows)
        summary.append(f'| {char} | {original} | {derived} | {missing} |')
    summary += ['', '## Missing states', '']
    for char in CHARACTERS:
        states = ', '.join(r['state'] for r in all_rows if r['characterId']==char and r['status']=='missing')
        summary.append(f'- **{char}:** {states or "none"}')
    summary += ['', 'Original illustration source, animation review, low-end Android battery test, Flutter integration, accessibility and iOS fallback are separate release gates.',
                'The 5×15 glossy infographic is NOT a production sprite library and must never be counted.', '',
                '## QA problems', *(['- '+x for x in problems] if problems else ['- None']), '']
    MD.write_text('\n'.join(summary),encoding='utf-8')
    print(f'Clips: {available}/{total} candidate ({counters["originalIllustratedCandidates"]} original, {counters["derivedCandidates"]} derived); missing {counters["missing"]}; errors={len(problems)}')
    for item in problems: print('ERROR',item)
    return 1 if problems else 0

if __name__=='__main__':sys.exit(main())
