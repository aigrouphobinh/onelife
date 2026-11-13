# OneLife Visual Asset Library

Asset production is **before** app coding. Start with docs/DESIGN_BRAIN.md, docs/CHARACTER_ANIMATION_SPEC.md, docs/ASSET_QA.md and docs/ASSET_REGISTER.md.

## Structure
- characters/brain/master.svg: canonical brain vector.
- characters/brain/<state>/sheet.svg: frame-by-frame vector source. Four columns, cell 256×256.
- characters/brain/<state>/metadata.json: frames, timing, anchors and source/target files.
- characters/cat|dog|robot|sprout/master.svg: other selectable mascot master drawings.
- icons/*.svg: original UI symbols, 24×24.

## Render all animation atlases
```bash
python -m pip install 'CairoSVG==2.7.1' 'Pillow==11.0.0'
python tools/generate_character_assets.py
```

The script produces sheet.png, preview.gif, metadata.json and manifest.json. For true GitHub binary delivery, the GitHub workflow .github/workflows/mascot-assets.yml commits these generated files to main on source changes; verify that workflow permissions permit writes.

## Runtime integration contract
Do not use SVG sheet as a direct animated widget; crop per state according to metadata or pre-split atlases. Cache textures, stop off-screen playback, offer reduced motion and respect screen-time privacy. All other characters require their own animation sheets before calling the 5-character system complete.
