# OneLife V3.4 — Brain nổi Android: nghiệm thu thiết bị

**Trạng thái:** Source của BrainOverlayService và trang Flutter điều khiển đã được
đưa lên main. Chỉ nghiệm thu khi CI build thành công và thử trên điện thoại thật.

## Đúng cơ chế Android, không giả lập

- Android 8+ tạo cửa sổ TYPE_APPLICATION_OVERLAY bằng WindowManager; không dùng
  AccessibilityService hoặc một Flutter screen giả làm cửa sổ hệ thống.
- Chỉ khi người dùng chọn **Tôi → Trợ lý nổi Android → Mở cài đặt cấp quyền**
  và cấp quyền Hiển thị trên ứng dụng khác, sau đó nhấn **Hiện Brain nổi**,
  cửa sổ mới được yêu cầu khởi chạy.
- Mở trang quyền của Android KHÔNG có nghĩa đã được cấp quyền. Trạng thái được
  đọc lại bằng Settings.canDrawOverlays khi người dùng quay về OneLife.
- Service không exported, không tự bật lúc boot, không FOREGROUND_SERVICE,
  dùng START_NOT_STICKY. Android có thể dừng service khi thiếu tài nguyên.
- Hình Brain thực từ Flutter asset
  assets/characters-v2/brain/idle/sheet.png, 8 khung RGBA (4×2), 140 ms/khung.
- Kéo để đổi vị trí, ghi nhớ tọa độ, chạm để mở/đóng panel với 4 nút:
  Việc hôm nay, Ghi nhanh, Tập trung, Ẩn Brain.
- Overlay không tự đọc/chụp/thu thập giao diện của ứng dụng khác.
- iOS và Android dưới API 26 không được hiển thị nút bật overlay.

## Checklist kiểm thử trực tiếp

1. Chưa cấp quyền: mở màn thiết lập, Brain không tự xuất hiện.
2. Vào cài đặt rồi từ chối: quay lại vẫn chưa thể kích hoạt.
3. Cấp quyền: quay lại ứng dụng, nút Hiện Brain nổi được mở; không tự chạy.
4. Bật Brain: ra màn hình chính hoặc mở ứng dụng khác; thấy chính nhân vật
   Glossy Kawaii trong suốt, không phải khung/placeholder.
5. Hoạt ảnh idle chạy liên tục; không giật hoặc lệch khung.
6. Kéo Brain qua hai cạnh màn hình, không kẹt hoặc vượt biên.
7. Chạm Brain để mở menu; không cắt nút trên màn hình nhỏ.
8. Chạm ba nút thao tác, kiểm tra mở đúng Flutter Công việc/Ghi nhanh/Focus
   với dữ liệu thực (cả khi app chưa mở).
9. Chạm Ẩn Brain hoặc Ẩn Brain nổi trong Flutter: cửa sổ biến mất.
10. Bật lại: giữ vị trí sau lần kéo gần nhất.
11. Tắt quyền trong Settings: overlay không được khởi động lại.
12. Kiểm tra việc Android/OEM kết thúc service khi hạn chế pin; không
    tuyên bố overlay hoạt động vĩnh viễn hoặc tự khôi phục.
13. Kiểm thử trên Android 8, 13, 15/16 và nhiều launcher trước nghiệm thu.

## APK thử nghiệm

GitHub Actions: https://github.com/aigrouphobinh/onelife/actions/workflows/flutter.yml

Sau khi run ở main xanh, tải artifact onelife-v34-debug-apk, giải nén
app-debug.apk rồi cài bằng adb install -r app-debug.apk.

Bản build xanh là bằng chứng mã biên dịch được, KHÔNG thay thế QA vật lý.

Tham khảo nền tảng:
https://developer.android.com/reference/android/Manifest.permission#SYSTEM_ALERT_WINDOW
https://developer.android.com/reference/android/provider/Settings#canDrawOverlays(android.content.Context)
https://developer.android.com/about/versions/15/behavior-changes-15
