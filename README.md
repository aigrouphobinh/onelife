# OneLife

## Current Glossy Kawaii Dog checkpoint (2026-11-15)

**Source record coverage: 30/60 (50%)** — Cat 15/15, **Dog 15/15**, Robot 0/15 and Sprout 0/15. This is not visual approval, independent artwork coverage or a Flutter release status. The Brain pack is tracked separately.

- **Dog 15/15 source records:** final three `sad`, `balanced`, `strained` imported to `main` at commit `ce06a1e`. Each has a 12-frame 4×3 true-RGBA WebP, PNG atlas, GIF preview, metadata, SHA and renderer QA. [Source/art classification and acceptance gates](docs/DOG_LAST3_ART_QA.md).
- **14/15 independent Dog pose sources:** `strained` is currently a **retargeted** original illustration candidate, not 12 newly illustrated Strained acting frames. Keep its QA flag pending and replace with independently illustrated source before art signoff.
- **Flutter:** Home retains the note workflow and manual mascot previews; a dedicated [15-state Dog gallery](lib/src/dog_animation_gallery.dart) loads the 15 actual transparent PNG atlases (no SVG placeholders), supports replay and OS reduced-motion preferences. Related [widget tests](test/widget_test.dart), [pixel-alpha tests](test/glossy_sprite_test.dart) and [CI workflow](.github/workflows/flutter-glossy-sprite.yml) are committed.
- **Technical vs release:** source SHA and alpha/geometry/frame change checks have passed on GitHub; manual art acceptance, Flutter CI analyzer/test results, actual Android/iOS device compatibility and performance are not yet independently confirmed. Dog manifest keeps `productionReady=false`.
- **Next priority:** Robot 15 original Glossy Kawaii source states and Sprout 15 states; separately replace retargeted Strained poses and verify Flutter on hardware. [Next task](docs/NEXT_AUTO_TASK.md).

## Design V2 – Trợ lý bộ não nhỏ (2026-11-14)

**Công việc được triển khai trực tiếp trên `main`.** Thiết kế đã có bộ Brain Glossy V2 gồm **15 clip/156 frame** và 10 trang prototype, dùng sprite PNG thật (không dùng ảnh vẽ SVG phẳng cho nhân vật Brain).

- [**10-page interactive V2 prototype**](design/prototype-v2/index.html) · [Screenshots](design/prototype-v2/screenshots/) — bản thiết kế tương tác với **dữ liệu mẫu**, không phải Flutter hoạt động
- [**15-state Brain animation preview**](design/review/glossy-v2.html) · [Contact sheet](design/review/glossy-brain-v2-contact.png)
- [Brain V2 asset manifest](assets/characters-v2/brain/manifest.json) · [Status and provenance](docs/V2_STATUS.md)
- [Style Lock V2](design/STYLE_LOCK_V2.md) · [Brain Balance rules](docs/BRAIN_BALANCE_DESIGN.md)
- [Visual and device QA gates](docs/ART_DIRECTION_REVIEW.md)

**Nghiệm thu:** GitHub Actions kiểm thử cấu trúc và ảnh đã PASS. Trong 15 clip Brain, có 8 clip được xây dựng từ các tư thế Glossy đã có (composite) và cần vẽ các frame độc lập trước khi duyệt mỹ thuật cuối. **Tiến độ hiện tại: Mèo 15/15, Chó 15/15 (14 độc lập + 1 dựng lại), Robot 0/15 và Mầm xanh 0/15 nguồn clip (chưa nghiệm thu thiết bị)**, theo Issues [#31](https://github.com/aigrouphobinh/onelife/issues/31), [#32](https://github.com/aigrouphobinh/onelife/issues/32), [#33](https://github.com/aigrouphobinh/onelife/issues/33), [#34](https://github.com/aigrouphobinh/onelife/issues/34).

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
