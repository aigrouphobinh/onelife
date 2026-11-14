# OneLife

## Current Glossy Kawaii asset + Flutter checkpoint (2026-11-15)

**Original source coverage: 26/60 illustrated clips (34 missing)**, counted from `assets/characters-v2/animation_sources.json` on `main`. **This is not an approval or production-readiness percentage.**

- Cat **15/15**, Dog **11/15** (now including **Recovering, Focus, Study and Done**), Robot **0/15**, Sprout **0/15**. The Brain V2 package is tracked separately.
- Verified original 12-frame **Dog Done** WebP has real RGBA transparency, checksum-locked import, PNG atlas, GIF preview, metadata and clean technical QA. [Dog Done asset/acceptance record](docs/DOG_DONE_ART_BRIEF.md).
- **Flutter working slice:** Home supports four manual mascot preview states (**Hồi phục / Tập trung / Học tập / Hoàn thành**) using `GlossySprite` and true-alpha PNG atlases; replay, semantic labels and reduced-motion fallback are present. These are **preview selectors, not an automatic task-completion event engine**.
- [Dog Recovering](docs/DOG_RECOVERING_CANDIDATE_REVIEW.md) · [Dog Focus](docs/DOG_FOCUS_ART_BRIEF.md) · [Dog Study](docs/DOG_STUDY_ART_BRIEF.md) · [Dog Done](docs/DOG_DONE_ART_BRIEF.md). All four require human art and real-device review; Dog `productionReady=false`.
- **Next asset target:** Dog **Thinking**, then Sad, Balanced and Strained; Robot/Sprout migration follows. Do not claim a state is sourced until its actual alpha WebP and SHA exist on `main`.
- Flutter CI has been configured to run analyzer and widget smoke tests; **its passing status has not been independently confirmed**. The full 10-page Flutter app, real OS usage/notifications/overlay, battery and accessibility testing remain outstanding.
- `docs/NEXT_AUTO_TASK.md` tracks the next original-art task and may be rewritten by the deterministic worker.

## Design V2 – Trợ lý bộ não nhỏ (2026-11-14)

**Công việc được triển khai trực tiếp trên `main`.** Thiết kế đã có bộ Brain Glossy V2 gồm **15 clip/156 frame** và 10 trang prototype, dùng sprite PNG thật (không dùng ảnh vẽ SVG phẳng cho nhân vật Brain).

- [**10-page interactive V2 prototype**](design/prototype-v2/index.html) · [Screenshots](design/prototype-v2/screenshots/) — bản thiết kế tương tác với **dữ liệu mẫu**, không phải Flutter hoạt động
- [**15-state Brain animation preview**](design/review/glossy-v2.html) · [Contact sheet](design/review/glossy-brain-v2-contact.png)
- [Brain V2 asset manifest](assets/characters-v2/brain/manifest.json) · [Status and provenance](docs/V2_STATUS.md)
- [Style Lock V2](design/STYLE_LOCK_V2.md) · [Brain Balance rules](docs/BRAIN_BALANCE_DESIGN.md)
- [Visual and device QA gates](docs/ART_DIRECTION_REVIEW.md)

**Nghiệm thu:** GitHub Actions kiểm thử cấu trúc và ảnh đã PASS. Trong 15 clip Brain, có 8 clip được xây dựng từ các tư thế Glossy đã có (composite) và cần vẽ các frame độc lập trước khi duyệt mỹ thuật cuối. **Tiến độ hiện tại: Mèo 15/15, Chó 10/15, Robot 0/15 và Mầm xanh 0/15 nguồn clip (chưa nghiệm thu thiết bị)**, theo Issues [#31](https://github.com/aigrouphobinh/onelife/issues/31), [#32](https://github.com/aigrouphobinh/onelife/issues/32), [#33](https://github.com/aigrouphobinh/onelife/issues/33), [#34](https://github.com/aigrouphobinh/onelife/issues/34).

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
