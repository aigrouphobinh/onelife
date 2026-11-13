# OneLife Design Library

**Design-first project.** These are approved *source candidates*, not proof of production Flutter screens.

## What is here
- `screens/01-splash.svg` → Splash
- `screens/02-onboarding.svg` → Privacy-first onboarding
- `screens/03-home.svg` → Today's tasks and mascot
- `screens/04-tasks.svg` → Task list and add action
- `screens/05-schedule.svg` → Schedule and alarms
- `screens/06-habits.svg` → Opt-in usage insights
- `screens/07-assistant.svg` → Local AI / optional Gemini assistant
- `screens/08-characters.svg` → 5-character catalog
- `screens/09-settings.svg` → Privacy, model and personalization
- `screens/10-overlay-android.svg` → Android overlay example only

Matching PNG files are built from SVG sources by GitHub Actions. `screens/manifest.json` tracks PNG SHA-256.

## Source commands
```bash
python -m pip install 'CairoSVG==2.7.1' 'Pillow==11.0.0'
python tools/render_design_screens.py
```

## Implementation contract
Follow `docs/SCREEN_LAYOUT_CONTRACT.md` and `docs/DESIGN_BRAIN.md`. Treat 390×844 as *reference composition*, not fixed Flutter layout. Use responsive widgets, safe areas, accessible minimum target sizes and permission-denied states. Mockup text represents example data, not actual usage telemetry. 

## Gate
Do not begin building a production UI from these screens until designers confirm appearance, mascot shape/animation, mobile readability and dark mode. Asset runtime QA and iOS fallback paths remain outstanding.


## Dark-mode compositions
Ten independently generated dark SVG/PNG design screens are in `screens/dark/` with SHA256 manifest, created deterministically by `tools/render_dark_screens.py` and GitHub Actions. The review gallery switches both its background **and the actual page mockup** when toggling dark mode. These are not Flutter screenshots; accessibility contrast, typography and device behavior require separate sign-off.

## Brain Balance scenario designs
`design/wellbeing/` holds six distinct Brain Balance scenarios in light and dark versions (12 SVG + 12 PNG; `manifest.json`). The sample numbers are illustrations, not telemetry. Source renderer: `tools/render_brain_balance_design.py`; no external data or fonts. The design viewer offers an extra Brain Balance screen and can preview the selected wellbeing emotion.
