# OneLife V3.4 — Brain phản ứng theo thời gian dùng máy

## Triển khai thật

- Android: UsageInsights.kt dùng UsageStatsManager.queryEvents với quyền PACKAGE_USAGE_STATS chỉ sau khi người dùng bật Truy cập dữ liệu sử dụng trong Cài đặt.
- Flutter: Tôi → Trợ lý nổi Android → Xem dữ liệu sử dụng thực tế.
- Không tự bật quyền hoặc tự đọc theo dõi từ lần đầu mở ứng dụng.
- Không lưu tên ứng dụng, package name hay lịch sử sự kiện. Chỉ trả tổng phút xấp xỉ và nhãn trạng thái về Flutter, không tải lên server.
- Thiếu quyền, Android khóa hoặc chưa có sự kiện => Chưa có dữ liệu; tuyệt đối không tự điền 0 phút.
- Tính xấp xỉ từ sự kiện app foreground/background kể từ 00:00 địa phương. Các phiên đang chạy trước 00:00, đa cửa sổ, dữ liệu OEM bị thiếu hoặc đổi đồng hồ có thể gây sai lệch.
- Không có ngưỡng thời gian mặc định. Chỉ khi người dùng tự đặt mục tiêu phản ánh hằng ngày (30–720 phút) mới phân loại: dưới 80% mục tiêu = balanced (xanh, 8 khung); từ 80% đến dưới 100% = strained (vàng, 10 khung); từ 100% = overloaded (hồng, 12 khung). Đây là mục tiêu cá nhân, không phải tiêu chuẩn sức khỏe hay thước đo sử dụng liên tục.
- Brain nổi làm mới khoảng 5 phút/lần. Nếu Focus đang chạy, ưu tiên 8 khung animation Focus thực đã có. Không có dữ liệu thì giữ biểu cảm trung tính.
- Chấm màu phụ trợ đi kèm đúng các sprite atlas PNG Balanced/Strained/Overloaded đã có trong repo. Một số atlas là bản ghép tư thế chờ duyệt thủ công, KHÔNG phải artwork final. Khi chưa đặt mục tiêu hoặc chưa có quyền, Brain giữ Idle trung tính.

## Checklist kiểm thử điện thoại Android

1. Không có Usage Access: không hiện 0 phút, app không tự hỏi quyền.
2. Nhấn nút mở đặc quyền, từ chối rồi quay lại: vẫn chưa được phép.
3. Cấp quyền và quay lại: Android trả số liệu thật hoặc thiếu dữ liệu; không hiển thị dữ liệu mẫu.
4. Theo dõi số liệu sau sử dụng một vài ứng dụng; đối chiếu Digital Wellbeing và ghi nhận sai khác.
5. Bật Brain ngoài app trước khi đặt mục tiêu: hình Idle trung tính, không tự gắn nhãn mệt mỏi. Sau khi tự chọn mục tiêu, kiểm tra Balanced/Strained/Overloaded với atlas đúng metadata.
6. Chạy Focus từ Quick Settings: hình Brain chuyển sang atlas Focus (8 khung, 160 ms) và ưu tiên Focus. Hết phiên thì trở về trạng thái mục tiêu nếu dữ liệu có sẵn hoặc Idle nếu không.
7. Thu hồi quyền khi Brain nổi vẫn đang chạy: lần cập nhật tới phải về unknown/trung tính.
8. Đổi giờ hoặc múi giờ, qua 00:00, máy khóa, đa cửa sổ: số liệu vẫn được ghi nhãn xấp xỉ.
9. iOS: không xuất hiện thời lượng dùng Android giả.
10. Xác nhận overlay không chụp hoặc đọc nội dung ứng dụng khác.
11. Chọn mục tiêu 60/120/180/240/360 phút rồi tắt; khởi động lại app để kiểm tra lưu/thu hồi mục tiêu thật.
12. Thử Android giảm chuyển động và chế độ tiết kiệm pin; kiểm tra sprite không bắt buộc chạy liên tục.

## Giới hạn và nghiệm thu

Usage Access khác SYSTEM_ALERT_WINDOW. Không gộp hai quyền; người dùng có thể thu hồi độc lập. Nhắc nghỉ không có nghĩa người dùng bị tổn thương não hoặc bị bệnh. Không tự khóa ứng dụng.

Chỉ kết luận hoạt động trên thiết bị thật sau khi Flutter tests, Android Kotlin/APK build, và các bước cấp quyền/thử trên máy đều đạt.

Nguồn:
https://developer.android.com/reference/android/app/usage/UsageStatsManager
https://developer.android.com/reference/android/app/usage/UsageEvents
https://developer.android.com/reference/android/provider/Settings#ACTION_USAGE_ACCESS_SETTINGS
