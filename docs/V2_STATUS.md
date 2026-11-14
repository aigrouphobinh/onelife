# OneLife – Brain Glossy V2 status (2026-11-14)

**15/15 trạng thái có asset V2 trên main; 156 khung hình; sản phẩm chưa được nghiệm thu mỹ thuật hoặc kiểm thử điện thoại.**

## Bảy clip Glossy đã tạo trước đó

| Trạng thái | Frame | Kiểu tạo | Trạng thái |
|---|---:|---|---|
| idle | 8 | Glossy painted raster | Đã có trên GitHub, chưa duyệt thiết bị |
| remind | 12 | Glossy painted raster | Chưa duyệt thiết bị |
| happy | 12 | 12 illustrated key poses | Chưa duyệt thiết bị |
| overloaded | 12 | 12 illustrated key poses | Chưa duyệt thiết bị |
| alarm | 12 | 12 illustrated key poses | Chưa duyệt thiết bị |
| sleepy | 12 | 12 illustrated key poses | Chưa duyệt thiết bị |
| recovering | 12 | 12 illustrated key poses | Chưa duyệt thiết bị |

## 8 clip ứng viên ghép từ tư thế Glossy có sẵn

| State | Frame | Đặc điểm riêng |
|---|---:|---|
| focus | 8 | Chú ý bàn làm việc, máy tính |
| study | 12 | Sách mở và lật trang |
| done | 12 | Dấu tích, ánh sao chúc mừng |
| thinking | 8 | Ô suy nghĩ, dấu hỏi và góc nhìn |
| sad | 8 | Biểu cảm đồng cảm, giọt nước mắt nhỏ |
| balanced | 8 | Ánh xanh dịu, nhịp cân bằng |
| strained | 10 | Mệt nhẹ, giọt mồ hôi, không chuẩn đoán bệnh |
| resting | 10 | Đệm nghỉ, thở chậm, chuyển động nhẹ |

Tất cả tám clip này dùng nguồn ảnh bóng có sẵn, **không phải animation minh họa độc lập vẽ mới**. Metadata ghi `generationClass=derived-pose-composite`. Về mỹ thuật, chỉ tính là **candidate**.

## Tổng hợp

- 7 clip raster Glossy V2 có nguồn tư thế riêng hoặc nguồn đã tạo từ trước: 80 frame.
- 8 clip review composite: 76 frame.
- Tổng: 15 clip, 156 frame; 15 sheet PNG + WebP + GIF + metadata ở `assets/characters-v2/brain`, mirror ở `assets/characters/brain`.
- `productionReady=false`. Không sử dụng 15/15 như bằng chứng tính năng đã hoàn thành trên Flutter.
- Cần art review 64px/96px/144px; chuyển động loop, pin, accessibility; 4 nhân vật còn lại chưa Glossy V2; native usage tracking chưa xây dựng.

## Công cụ

- `tools/build_brain_v2_remaining.py` là pipeline có thể tái lập cho 8 clip composited.
- `design/review/glossy-v2.html` xem đủ 15 clip.
- `tools/check_glossy_v2_assets.py` là QA kỹ thuật.
- Nguồn gốc/giới hạn minh họa được ghi trong `docs/ASSET_REGISTER.md`.
