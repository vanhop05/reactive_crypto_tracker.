# CryptoPulse Reactive — Ứng Dụng Đa Nền Tảng Theo Dõi Thị Trường Thời Gian Thực

> **Môn học:** Lập Trình Đa Nền Tảng  
> **Chủ đề 02:** Lập trình Bất đồng bộ với Future & Stream: Xây dựng Module Reactive thời gian thực  
> **Nền tảng mục tiêu:** Đa nền tảng (Hỗ trợ chính thức: **Android**, **iOS**, **Web**, **Windows Desktop**)  
> **Ngôn ngữ:** Dart 3.x & Flutter Framework  
> **Quy mô:** Nhóm 02 sinh viên  
> 
> **THÀNH VIÊN THỰC HIỆN:**
> 1. **Trần Văn Hợp** (Trưởng nhóm - Business Logic, State Management, Event Loop Engine, Unit Testing)
> 2. **Mai Tuấn An** (Thành viên - UI/UX Design, Data Visualization, Multiplatform Native, Báo cáo & Video)

---

## MỤC LỤC
1. [Giới Thiệu Dự Án](#gioi-thieu-du-an)
2. [Tính Năng Nổi Bật Đáp Ứng Chuẩn Đề Tài](#tinh-nang-noi-bat)
3. [Kiến Trúc Kỹ Thuật (Event Loop, Stream, Transformers)](#kien-truc-ky-thuat)
4. [Cấu Hình Biến Môi Trường (.env) & Google Services](#cau-hinh-bien-moi-truong)
5. [Hướng Dẫn Cài Đặt & Chạy Ứng Dụng (Android, iOS, Web)](#huong-dan-cai-dat)
6. [Bảng Phân Chia Công Việc & Kịch Bản Commit Git](#phan-chia-cong-viec)
7. [Kịch Bản Quay Video Clip Thao Tác Thực Tế & Thuyết Trình](#kich-ban-video)
8. [Kiểm Thử Tự Động (Unit Testing)](#kiem-thu-tu-dong)

---

<a id="gioi-thieu-du-an"></a>
## GIỚI THIỆU DỰ ÁN

**CryptoPulse Reactive** là ứng dụng di động đa nền tảng được xây dựng nhằm giải quyết bài toán xử lý và hiển thị luồng dữ liệu biến động cực nhanh trong thời gian thực (real-time high-frequency streaming) mà không làm lag giao diện người dùng, đồng thời quản lý bộ nhớ an toàn tuyệt đối.

Ứng dụng hiện thực hóa đầy đủ các yêu cầu cốt lõi của **Chủ đề 02**:
* Mô hình xử lý bất đồng bộ trong Dart: **Event Loop**, **Call Stack**, **Microtask Queue**, **Event Queue**, **Future**, và **async/await**.
* Cơ chế phản ứng dữ liệu hướng luồng: **Stream**, **StreamController.broadcast()**, đa lắng nghe (Multi-subscriber).
* Các toán tử biến đổi dữ liệu tùy biến: **Debounce** (lọc tìm kiếm thông minh) và **Throttle** (tiết giảm tần suất cập nhật UI).
* **Quản lý vòng đời luồng & Hủy an toàn (Cancellation / Dispose):** Chủ động ngắt kết nối `StreamSubscription` khi chuyển trang/thoát màn hình, ngăn ngừa triệt để lỗi Memory Leak và Zombie Listeners.

---

<a id="tinh-nang-noi-bat"></a>
## TÍNH NĂNG NỔI BẬT ĐÁP ỨNG CHUẨN ĐỀ TÀI

| Nhóm Tính Năng | Mô Tả Kỹ Thuật | Ứng Dụng Thực Tế Trong App |
| :--- | :--- | :--- |
| **Real-time Price Engine** | Sử dụng `StreamController<MarketTick>.broadcast()` phát sinh các biến động giá ngẫu nhiên theo mô hình chuyển động Brown. | Bảng giá Bitcoin, Ethereum, Solana... nhảy số liên tục kèm hiệu ứng nhấp nháy xanh/đỏ (Glow Flash Animation). |
| **Debounced Search** | Triển khai toán tử `DebounceStreamTransformer` (400ms) gộp nhiều sự kiện gõ phím liên tiếp thành 1 sự kiện duy nhất. | Thanh tìm kiếm coin không gửi request thừa khi đang gõ; chỉ lọc khi người dùng dừng tay 400ms. |
| **Throttled Detail Stream** | Triển khai toán tử `ThrottleStreamTransformer` (300ms) giới hạn số khung hình render lại. | Màn hình chi tiết nhận tick với tần số cao nhưng chỉ render UI tối đa 1 lần/300ms, tiết kiệm CPU và pin. |
| **Interactive Event Loop Lab** | Mô phỏng trực quan Call Stack, Microtask Queue (`scheduleMicrotask`), và Event Queue (`Future`). | Người dùng nhấn nút "Chạy Thử" để xem trực tiếp thứ tự thực thi với mốc thời gian đo bằng microsecond (µs). |
| **Stream Lifecycle Monitor** | Giám sát trạng thái luồng, bộ đếm active listeners, và nút toggle "Giả Lập Rò Rỉ Bộ Nhớ" vs "Hủy Luồng An Toàn". | Khi nhấn Back thoát khỏi màn hình chi tiết, `dispose()` gọi `_tickSubscription.cancel()`, số subscriber giảm ngay về trạng thái an toàn. |
| **Real-time Order Book** | Phát sinh và cập nhật liên tục độ sâu sổ lệnh Bids (Mua) và Asks (Bán) theo thời gian thực. | Khối Sổ lệnh phản ánh đúng dòng tiền thị trường dạng bảng song song. |

---

<a id="kien-truc-ky-thuat"></a>
## KIẾN TRÚC KỸ THUẬT

### 1. Mô Hình Dart Event Loop & Hai Hàng Đợi (Queues)

```
        +-----------------------------------------+
        |            Main Call Stack              |
        |  (Thực thi mã lệnh đồng bộ tuần tự)      |
        +--------------------+--------------------+
                             | (Khi Stack trống)
                             v
        +-----------------------------------------+
        |            Microtask Queue              |
        |  - scheduleMicrotask()                  |
        |  - Future.microtask()                   |
        |  (Ưu tiên TUYỆT ĐỐI trước Event Queue)  |
        +--------------------+--------------------+
                             | (Khi Microtask Queue trống)
                             v
        +-----------------------------------------+
        |              Event Queue                |
        |  - Future()                             |
        |  - Future.delayed()                     |
        |  - Stream events                        |
        |  - User Touch / I/O Network Events      |
        +-----------------------------------------+
```

### 2. So Sánh Single-Subscription vs Broadcast Stream

* **Single-Subscription Stream:** Chỉ cho phép 1 listener duy nhất (ví dụ đọc file từ ổ đĩa). Nếu gọi `.listen()` lần thứ hai sẽ ném ngoại lệ `StateError: Stream has already been listened to`.
* **Broadcast Stream:** Sử dụng `StreamController<T>.broadcast()`. Cho phép bất kỳ Widget nào trong cây Widget đăng ký lắng nghe và hủy lắng nghe độc lập mà không ảnh hưởng tới các Widget khác.

### 3. Cơ Chế Hủy Luồng An Toàn (Safe Stream Cancellation)

Khi người dùng mở màn hình chi tiết `CryptoDetailScreen`, một subscription được tạo ra:
```dart
@override
void initState() {
  super.initState();
  _tickSubscription = CryptoPriceStreamService.instance
      .getStreamForSymbol(widget.initialAsset.symbol)
      .throttle(const Duration(milliseconds: 300))
      .listen((tick) {
        if (mounted) setState(() { ... });
      });
}
```

Nếu người dùng thoát màn hình mà không hủy subscription, Stream tiếp tục gọi `setState()` trên một Widget đã unmounted, gây lỗi `setState() called after dispose()` và chiếm dụng RAM vĩnh viễn (Zombie Listener). Vì vậy, cơ chế hủy an toàn được áp dụng:
```dart
@override
void dispose() {
  // Hủy subscription an toàn
  _tickSubscription?.cancel();
  _tickSubscription = null;
  _orderBookSub?.cancel();
  _orderBookSub = null;
  _orderBookService.dispose();
  super.dispose();
}
```

---

<a id="cau-hinh-bien-moi-truong"></a>
## CẤU HÌNH BIẾN MÔI TRƯỜNG (.env) & GOOGLE SERVICES

### 1. Biến môi trường (`.env`)
Dự án đã chuẩn bị sẵn file mẫu [`.env.example`](file:///.env.example). Để thiết lập, sao chép file thành `.env`:
```bash
cp .env.example .env
```
Nội dung file cấu hình:
```properties
CRYPTO_API_BASE_URL=https://api.coingecko.com/api/v3
CRYPTO_WEBSOCKET_URL=wss://stream.binance.com:9443/ws
ENABLE_MOCK_FALLBACK=true
STREAM_TICK_INTERVAL_MS=1200
DEBOUNCE_DURATION_MS=400
THROTTLE_DURATION_MS=600
APP_NAME=CryptoPulse Reactive
APP_ENVIRONMENT=development
```

### 2. Cấu hình Google Services (Android / iOS)
* **Android:** File mẫu đặt tại [`android/app/google-services.json.example`](file:///android/app/google-services.json.example). Khi kết nối Firebase thực tế, đổi tên file thành `google-services.json` và đặt vào thư mục `android/app/`.
* **iOS:** Khi dùng Firebase iOS, đặt file `GoogleService-Info.plist` vào thư mục `ios/Runner/`.

---

<a id="huong-dan-cai-dat"></a>
## HƯỚNG DẪN CÀI ĐẶT & CHẠY ỨNG DỤNG

Dự án tương thích hoàn toàn với Flutter 3.10+ và Dart 3.0+.

### Bước 1: Tải các gói phụ thuộc (Dependencies)
Mở terminal tại thư mục gốc của dự án (`reactive_crypto_tracker`):
```bash
flutter pub get
```

### Bước 2: Kiểm tra thiết bị khả dụng
```bash
flutter devices
```

### Bước 3: Biên dịch & Chạy trên các hệ điều hành

#### 1. Chạy trên Android (Real Device & Emulator)
* **Máy ảo (Emulator):** Mở Android Studio -> Virtual Device Manager -> Khởi động máy ảo Pixel/Galaxy.
* **Thiết bị thật (Real Device):**
  1. Cắm cáp USB vào máy tính.
  2. Bật **Developer Options (Tùy chọn cho nhà phát triển)** trên điện thoại.
  3. Bật **USB Debugging (Gỡ lỗi qua USB)**.
* Chạy lệnh:
```bash
flutter run -d android
```

#### 2. Chạy trên iOS (iPhone Simulator & Real iPhone)
* **Máy ảo (iOS Simulator):** Mở ứng dụng Simulator trên macOS.
* **iPhone thật:** Kết nối cáp Lightning/Type-C, tin cậy máy tính và bật Developer Mode trên iOS.
* Chạy lệnh:
```bash
flutter run -d ios
```

#### 3. Chạy trên Web (Google Chrome)
Để kiểm tra giao diện nhanh chóng trên máy tính:
```bash
flutter run -d chrome
```

#### 4. Chạy trên Windows Desktop
```bash
flutter run -d windows
```

---

<a id="phan-chia-cong-viec"></a>
##  BẢNG PHÂN CHIA CÔNG VIỆC (WORK BREAKDOWN STRUCTURE - WBS) & KỊCH BẢN COMMIT GIT

### 1. Bảng Phân Công Công Việc Chi Tiết (WBS)

| Thành Viên | Vai Trò Chính | Các File Trực Tiếp Phụ Trách & Lập Trình | Chi Tiết Nhiệm Vụ & Đóng Góp |
| :--- | :--- | :--- | :--- |
| **Trần Văn Hợp**<br>*(Trưởng nhóm)* | • Business Logic<br>• State Management<br>• Reactive Core<br>• Unit Testing | 1. `lib/services/crypto_price_stream_service.dart`<br>2. `lib/services/event_loop_simulator_service.dart`<br>3. `lib/core/transformers/stream_transformers.dart`<br>4. `lib/models/market_tick.dart`<br>5. `lib/models/crypto_asset.dart`<br>6. `lib/models/event_loop_step.dart`<br>7. `test/stream_transformers_test.dart`<br>8. `test/crypto_price_stream_service_test.dart`<br>9. `test/event_loop_order_test.dart`<br>10. `test/verify_pure_dart.dart`<br>11. `pubspec.yaml` & `analysis_options.yaml` | • Thiết kế toàn bộ kiến trúc bất đồng bộ và luồng dữ liệu phản ứng (Reactive Stream Architecture).<br>• Xây dựng Broadcast StreamController phát sinh giá thời gian thực và quản lý bộ đếm Active Subscribers.<br>• Tự tay lập trình toán tử tùy biến `DebounceStreamTransformer` và `ThrottleStreamTransformer`.<br>• Hiện thực hóa Engine đo thời gian và mô phỏng thứ tự Event Loop & Microtask Queue (đo microsecond).<br>• Viết toàn bộ 100% test suite kiểm thử tự động (Unit Tests) xác thực thuật toán. |
| **Mai Tuấn An** | • UI/UX Design<br>• Multi-Platform Native<br>• Data Visualization<br>• Sổ lệnh (Order Book)<br>• Báo cáo / Slide / Video | 1. `lib/core/theme/app_theme.dart`<br>2. `lib/widgets/mini_price_chart.dart`<br>3. `lib/widgets/price_ticker_card.dart`<br>4. `lib/widgets/order_book_widget.dart`<br>5. `lib/widgets/stream_lifecycle_badge.dart`<br>6. `lib/services/order_book_stream_service.dart`<br>7. `lib/models/order_book_entry.dart`<br>8. `lib/views/main_navigation_screen.dart`<br>9. `lib/views/crypto_market_screen.dart`<br>10. `lib/views/crypto_detail_screen.dart`<br>11. `lib/views/event_loop_lab_screen.dart`<br>12. `lib/views/stream_operators_lab_screen.dart`<br>13. `lib/views/architecture_guide_screen.dart`<br>14. `lib/main.dart`<br>15. `README.md` & `.env.example`<br>16. Cấu hình Native: `android/`, `ios/`, `web/`, `windows/` | • Thiết kế giao diện Dark Fintech Theme hiện đại, bảng màu chuẩn nến xanh/đỏ cho thị trường tài chính.<br>• Xây dựng CustomPainter vẽ biểu đồ nến/sparkline thời gian thực (`MiniPriceChart`).<br>• Tạo hiệu ứng nhấp nháy phát sáng (Pulse Glow Animation) khi giá coin biến động.<br>• Xây dựng giao diện hiển thị sổ lệnh Bids/Asks (`OrderBookWidget`).<br>• Thiết kế màn hình chi tiết coin với giao diện trực quan kiểm thử Hủy luồng an toàn (Dispose) vs Giả lập rò rỉ RAM.<br>• Cấu hình nền tảng gốc Android, iOS, Web, Windows Desktop.<br>• Soạn thảo báo cáo kỹ thuật `README.md`, file môi trường `.env`, kịch bản thuyết trình và quay video clip. |

---

### 2. Commit Git Của Các Thành Viên

```bash
# 1. Khởi tạo Git repository [Trần Văn Hợp]
git init
git branch -M main

# 2. COMMIT 1: Trần Văn Hợp (Khởi tạo kiến trúc Core, Stream Service & Models)
git config user.name "Tran Van Hop"
git config user.email "Tranvanhopcr7@gmail.com"
git add pubspec.yaml analysis_options.yaml .gitignore lib/models/market_tick.dart lib/models/crypto_asset.dart lib/models/event_loop_step.dart lib/services/crypto_price_stream_service.dart lib/services/event_loop_simulator_service.dart
git commit -m "feat(core): initialize reactive stream architecture and price simulation engine [Tran Van Hop]"

# 3. COMMIT 2: Mai Tuấn An (Thiết kế Dark Theme, Custom Widgets, Order Book & Native Android/iOS)
git config user.name "Mai Tuan An"
git config user.email "11a1maituanan@gmail.com"
git add .env.example lib/core/theme/ lib/models/order_book_entry.dart lib/services/order_book_stream_service.dart lib/widgets/ android/ ios/ web/ windows/ linux/ macos/
git commit -m "feat(ui): design fintech dark theme, order book, custom painters, and multiplatform configs [Mai Tuan An]"

# 4. COMMIT 3: Trần Văn Hợp (Toán tử Debounce/Throttle & Toàn bộ Unit Test Suite)
git config user.name "Tran Van Hop"
git config user.email "Tranvanhopcr7@gmail.com"
git add lib/core/transformers/stream_transformers.dart test/
git commit -m "feat(operators): implement custom debounce/throttle transformers and unit tests [Tran Van Hop]"

# 5. COMMIT 4: Mai Tuấn An (Toàn bộ Màn hình giao diện, Giám sát hủy luồng & Tài liệu README)
git config user.name "Mai Tuan An"
git config user.email "11a1maituanan@gmail.com"
git add lib/views/ lib/main.dart README.md
git commit -m "feat(views): implement responsive market screens, safe disposal lifecycle UI, and documentation [Mai Tuan An]"

# 6. Đẩy lên GitHub công khai [Trần Văn Hợp]
git remote add origin https://github.com/vanhop05/reactive_crypto_tracker..git
git push -u origin main
```

---
<a id="kiem-thu-tu-dong"></a>
##  KIỂM THỬ TỰ ĐỘNG (UNIT TESTING)

Dự án đi kèm các bộ kiểm thử tự động xác thực toàn diện:
1. `test/stream_transformers_test.dart`: Kiểm tra toán tử Debounce và Throttle.
2. `test/crypto_price_stream_service_test.dart`: Kiểm tra đa kết nối Broadcast Stream.
3. `test/event_loop_order_test.dart`: Kiểm tra thứ tự ưu tiên Microtask vs Event Queue.
4. `test/verify_pure_dart.dart`: Script kiểm thử độc lập chạy trực tiếp qua Dart SDK.

### Lệnh chạy kiểm thử nhanh:
```bash
dart run test/verify_pure_dart.dart
```
Kết quả hiển thị trên console:
```text
=============================================
 CHẠY KIỂM THỬ TỰ ĐỘNG CHỦ ĐỀ 02 (DART TEST)
=============================================
[Test 1] Kiểm tra thứ tự Event Loop & Microtask Queue:
  -> PASS: Thứ tự ưu tiên chính xác tuyệt đối: Sync -> Microtasks -> Future.

[Test 2] Kiểm tra Toán tử DebounceStreamTransformer:
  -> PASS: Debounce hoạt động chính xác.

[Test 3] Kiểm tra Broadcast Stream & Hủy Luồng An Toàn:
  -> Active subscribers: 1
  -> Đã nhận: Sub1=1 ticks, Sub2=1 ticks.
  -> PASS: Đã hủy sub1 & sub2 an toàn. Subscribers giảm từ 1 về 0.

=> TOÀN BỘ CÁC BÀI TEST CHỦ ĐỀ 02 ĐÃ VƯỢT QUA 100%
```
