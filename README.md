# OneLife

## Current Glossy Kawaii source + Flutter checkpoint (2026-11-15)

**Source records: 42/60 (70%)** — Cat **15/15**, Dog **15/15**, Robot **12/15**, Sprout **0/15**. This measures versioned original illustration sources, **not** human-approved artwork or mobile release readiness. Brain V2 is tracked separately.

- **Robot Thinking imported:** 12-frame 4×3 RGBA WebP source, exact SHA-256 `ed3a1577a6996a02361d0939b6fcfd5047c4daa8e937bae751060f66f5b1626a`, derived transparent PNG/GIF, frame metadata and QA on `main`. [Robot art/status record](docs/ROBOT_V2_CANDIDATE_IMPORT.md) · [GitHub import](https://github.com/aigrouphobinh/onelife/commit/2eb6f8b95b92).
- **Robot Flutter gallery:** `lib/src/robot_animation_gallery.dart` previews the 12 committed Robot atlases, with actual frame timing, replay, semantic labels and reduced-motion support; `pubspec.yaml` bundles those PNGs. Existing Dog gallery still exposes 15 actual sources. These are **manual previews** rather than OS screen-time or mental-health measurements.
- **Remaining art:** Robot `sad`, `balanced`, `strained` (three independent illustrated 4×3 sheets), then 15 Sprout sources. Do not register poster/contact-sheet art as a sprite.
- **Dog source milestone:** 15/15 catalog records, of which 14 have independently illustrated acting; Dog `strained` is a retargeted illustration requiring genuine rework before human signoff. [Dog acceptance note](docs/DOG_LAST3_ART_QA.md).
- **Open gates:** Flutter analyzer/CI results on the latest Robot gallery are not independently verified. Character-master consistency, transparent edge quality at 64/96/144px, performance/accessibility on Android and iOS, and human art acceptance remain pending. Manifests keep `productionReady=false`.

## Design V2 – Trợ lý bộ não nhỏ (2026-11-14)

**Công việc được triển khai trực tiếp trên `main`.** Thiết kế đã có bộ Brain Glossy V2 gồm **15 clip/156 frame** và 10 trang prototype, dùng sprite PNG thật (không dùng ảnh vẽ SVG phẳng cho nhân vật Brain).

- [**10-page interactive V2 prototype**](design/prototype-v2/index.html) · [Screenshots](design/prototype-v2/screenshots/) — bản thiết kế tương tác với **dữ liệu mẫu**, không phải Flutter hoạt động
- [**15-state Brain animation preview**](design/review/glossy-v2.html) · [Contact sheet](design/review/glossy-brain-v2-contact.png)
- [Brain V2 asset manifest](assets/characters-v2/brain/manifest.json) · [Status and provenance](docs/V2_STATUS.md)
- [Style Lock V2](design/STYLE_LOCK_V2.md) · [Brain Balance rules](docs/BRAIN_BALANCE_DESIGN.md)
- [Visual and device QA gates](docs/ART_DIRECTION_REVIEW.md)

**Nghiệm thu:** GitHub Actions kiểm thử cấu trúc và ảnh đã PASS. Trong 15 clip Brain, có 8 clip được xây dựng từ các tư thế Glossy đã có (composite) và cần vẽ các frame độc lập trước khi duyệt mỹ thuật cuối. **Tiến độ hiện tại: Mèo 15/15, Chó 15/15 (14 độc lập + 1 dựng lại), Robot 12/15 và Mầm xanh 0/15 nguồn clip (chưa nghiệm thu thiết bị)**, theo Issues [#31](https://github.com/aigrouphobinh/onelife/issues/31), [#32](https://github.com/aigrouphobinh/onelife/issues/32), [#33](https://github.com/aigrouphobinh/onelife/issues/33), [#34](https://github.com/aigrouphobinh/onelife/issues/34).

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
