# OneLife

## Current asset-first production checkpoint (2026-11-15)

**Source-illustration coverage: 23/60 clips (37 missing)**, verified from `assets/characters-v2/animation_sources.json` on `main`. This measures original illustration sources, **not** approved or production-ready animations. `docs/NEXT_AUTO_TASK.md` is auto-generated and may lag until its next scheduled update.

- Cat: 15/15 source clips; Dog: 8/15 including Recovering; Robot and Sprout: 0/15 each. The existing Brain pack is tracked separately from this 60-clip migration.
- **Dog Recovering imported on `main`:** original Glossy Kawaii 12-frame WebP with **real alpha**, 1024×768, verified SHA-256, generated PNG/GIF/metadata and QA. Its `productionReady` remains false pending visual and device review. [Review details](docs/DOG_RECOVERING_CANDIDATE_REVIEW.md).
- Keep the **Glossy Kawaii V2** master identity and real frame-by-frame movement. Do not fill missing frames with transformed stills, placeholders, or an unlabeled poster.
- Run source provenance, SHA-256 registration, sprite render and visual QA gates before promoting coverage. No device art approval, Flutter runtime, or production release is implied by passing GitHub Actions.
- **Flutter runtime integration started:** `lib/src/glossy_sprite.dart` now loads the real transparent `dog/recovering/sheet.png` from the Flutter asset bundle and paints individual RGBA frames. The Home page displays the mascot with replay; one-shot timing, accessibility semantics and reduced-motion support are implemented. `test/glossy_sprite_test.dart` and `.github/workflows/flutter-glossy-sprite.yml` provide smoke checks. Flutter CI and real phone sign-off have not been verified yet.
- **Dog Focus:** new transparent 12-pose candidate exported locally; binary source import and approval pending. [Focus brief and QA](docs/DOG_FOCUS_ART_BRIEF.md). Migration coverage remains **23/60** until the exact source is committed and cataloged.
- The next asset task is **import and review Dog Focus → remaining Dog states → Robot/Sprout**, alongside real-device validation and final Recovering→Idle motion review.


## Design V2 – Trợ lý bộ não nhỏ (2026-11-14)

**Công việc được triển khai trực tiếp trên `main`.** Thiết kế đã có bộ Brain Glossy V2 gồm **15 clip/156 frame** và 10 trang prototype, dùng sprite PNG thật (không dùng ảnh vẽ SVG phẳng cho nhân vật Brain).

- [**10-page interactive V2 prototype**](design/prototype-v2/index.html) · [Screenshots](design/prototype-v2/screenshots/) — bản thiết kế tương tác với **dữ liệu mẫu**, không phải Flutter hoạt động
- [**15-state Brain animation preview**](design/review/glossy-v2.html) · [Contact sheet](design/review/glossy-brain-v2-contact.png)
- [Brain V2 asset manifest](assets/characters-v2/brain/manifest.json) · [Status and provenance](docs/V2_STATUS.md)
- [Style Lock V2](design/STYLE_LOCK_V2.md) · [Brain Balance rules](docs/BRAIN_BALANCE_DESIGN.md)
- [Visual and device QA gates](docs/ART_DIRECTION_REVIEW.md)

**Nghiệm thu:** GitHub Actions kiểm thử cấu trúc và ảnh đã PASS. Trong 15 clip Brain, có 8 clip được xây dựng từ các tư thế Glossy đã có (composite) và cần vẽ các frame độc lập trước khi duyệt mỹ thuật cuối. **4 nhân vật Mèo/Chó/Robot/Mầm xanh chưa được chuyển sang phong cách V2**, theo Issues [#31](https://github.com/aigrouphobinh/onelife/issues/31), [#32](https://github.com/aigrouphobinh/onelife/issues/32), [#33](https://github.com/aigrouphobinh/onelife/issues/33), [#34](https://github.com/aigrouphobinh/onelife/issues/34).

**Chưa hoàn thành:** phần lớn Flutter runtime (mới tích hợp widget sprite cho Home), Android UsageStats/overlay/báo thức, iOS Screen Time (giới hạn quyền), AI offline, Gemini tùy chọn, kiểm thử pin và phát hành store.


One place to remember, find, and finish things.

Privacy-first, offline-first personal assistant for Android and iOS.

## MVP
- Capture notes and links
- Search saved content
- Convert notes into tasks
- Schedule local reminders
- Export personal data

## Stack
Flutter + Dart; SQLite for local data. Optional AI and sync are later phases.

## Documentation
See `docs/` for requirements, architecture, delivery roadmap, security and testing.

**Status:** Foundation in progress. No production release yet.

## Design-first phase (2026-11-14)
- [AI implementation contract](docs/DESIGN_BRAIN.md) and [Screen Layout Contract](docs/SCREEN_LAYOUT_CONTRACT.md)
- [10 visual screen concepts](design/screens) and [design README](design/README.md)
- [75 V1 technical animation clips and 5 vector masters](assets/characters) (not all approved visually)
- [12 icons](assets/icons), [Asset QA](docs/ASSET_QA.md), [License register](docs/ASSET_REGISTER.md)
- Design asset delivery **does not** mean the Flutter mobile app is functional or released.

## Glossy V2 — art migration
- [Real Brain V2 master](assets/characters-v2/brain/master.png) and [12-frame reminder sprite](assets/characters-v2/brain/remind/sheet.png) are committed; artwork is still a review candidate.
- [Interactive browser art review](design/review/glossy-v2.html): compare old/new characters, play/pause and scrub frames, check 64/96/144px.
- [15-state motion board](docs/V2_MOTION_BOARD.md) and [migration status](docs/GLOSSY_V2_STATUS.md).
- **Original historical milestone:** Brain master + remind were first V2 assets; newer Cat/Dog assets are tracked separately in the current checkpoint above. Artwork acceptance and device testing remain outstanding.
