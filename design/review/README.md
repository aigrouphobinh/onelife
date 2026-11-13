# OneLife – Interactive Design Review

This is a **design-only** visual acceptance tool, not a functioning Flutter app or production API.

Open [index.html](index.html) after cloning/downloading the repository. The preview reads real transparent PNG sprite atlases and draws their frames onto HTML Canvas, including dark mode.

Review 5 character choices × 10 expressions; test 64/96/144px sizes; pause, scrub and frame-step. Browse 10 original mobile screen compositions, including the Android-only overlay concept. This runs without CDN, remote services, or user data.

The CI pipeline [Asset QA](../../.github/workflows/asset-qa.yml) validates PNG geometry, non-empty frame coverage, SHA256, 10 screen compositions, optional sounds and produces contact sheets + reports here. Automated pass is NOT art approval, accessibility sign-off, battery measurement or Android/iOS device testing.

Follow docs/DESIGN_BRAIN.md and docs/SCREEN_LAYOUT_CONTRACT.md before implementing app UI.