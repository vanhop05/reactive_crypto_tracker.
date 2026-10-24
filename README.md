# StreamBuilder Stopwatch

Ứng dụng bấm giờ đa nền tảng được xây dựng bằng Flutter. Ứng dụng minh họa
cách sử dụng `Stream`, `StreamController` và `StreamBuilder` để cập nhật giao
diện theo thời gian thực.

## Tính năng

- Hiển thị thời gian theo định dạng `MM:SS.hh`.
- Bắt đầu, tạm dừng và đặt lại đồng hồ.
- Cập nhật thời gian mỗi 10 mili-giây.
- Giao diện nền tối với màu nhấn cyan.
- Quản lý tài nguyên an toàn bằng cách hủy `Timer` và đóng `StreamController`
  khi màn hình bị hủy.

## Cấu trúc chính

| File | Vai trò |
| --- | --- |
| `lib/main.dart` | Khởi chạy ứng dụng và cấu hình `MaterialApp`. |
| `lib/app_colors.dart` | Tập trung các màu dùng trong giao diện. |
| `lib/stopwatch_logic.dart` | Quản lý bộ đếm thời gian, `Timer`, stream và định dạng thời gian. |
| `lib/stopwatch_screen.dart` | Hiển thị màn hình bấm giờ và các nút điều khiển bằng `StreamBuilder`. |

## Cách hoạt động

`StopwatchLogic` sử dụng `Stopwatch` của Dart để đo thời gian và một
`StreamController<int>` để phát số mili-giây hiện tại. Sau khi nhấn **Bắt đầu**,
`Timer.periodic` phát dữ liệu mới mỗi 10 mili-giây.

`StopwatchScreen` lắng nghe stream bằng `StreamBuilder<int>`. Mỗi giá trị mới
được phát ra sẽ làm phần hiển thị thời gian được dựng lại.

Các thao tác trên giao diện:

- **Bắt đầu**: bắt đầu hoặc tiếp tục đếm thời gian.
- **Tạm dừng**: dừng đồng hồ và giữ nguyên thời gian hiện tại.
- **Đặt lại**: dừng đồng hồ và đưa thời gian về `00:00.00`.

## Yêu cầu môi trường

- Flutter 3.10 trở lên
- Dart 3.0 trở lên

## Cài đặt và chạy

Tại thư mục gốc của dự án, chạy:

```bash
flutter pub get
flutter devices
flutter run
```

Có thể chỉ định nền tảng cụ thể:

```bash
flutter run -d chrome    # Web
flutter run -d windows   # Windows
flutter run -d android   # Android
flutter run -d ios       # iOS, cần macOS và Xcode
```

## Kiểm tra mã nguồn

```bash
flutter analyze
flutter test
```
