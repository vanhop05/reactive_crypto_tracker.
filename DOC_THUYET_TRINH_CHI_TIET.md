# TÀI LIỆU TOÀN DIỆN VỀ ĐỒ ÁN & HƯỚNG DẪN THUYẾT TRÌNH BẢO VỆ
## CHỦ ĐỀ 02: LẬP TRÌNH BẤT ĐỒNG BỘ VỚI FUTURE & STREAM: XÂY DỰNG MODULE REACTIVE THỜI GIAN THỰC
**Ứng Dụng: CryptoPulse Reactive - Real-time Market & Event Loop Visualizer**

---

## MỤC LỤC
1. [Thông Tin Đồ Án & Phân Công Nhiệm Vụ Thành Viên](#1-thông-tin-đồ-án--phân-công-nhiệm-vụ-thành-viên)
2. [Bản Chất Kỹ Thuật Cốt Lõi (Đọc Để Hiểu Sâu & Thuyết Trình)](#2-bản-chất-kỹ-thuật-cốt-lõi-đọc-để-hiểu-sâu--thuyết-trình)
   - 2.1. Bản chất đơn luồng (Single-thread) và Event Loop trong Dart
   - 2.2. Microtask Queue vs Event Queue: Cơ chế và thứ tự ưu tiên
   - 2.3. Phân biệt sâu sắc giữa `Future` và `Stream`
   - 2.4. Single-Subscription Stream vs Broadcast Stream
   - 2.5. Quản lý vòng đời Stream và Chống Thất Thoát Bộ Nhớ (Memory Leak)
   - 2.6. Biến đổi dữ liệu luồng với StreamTransformer (where, debounce, map)
3. [Kiến Trúc Phần Mềm & Giải Thích Chi Tiết Toàn Bộ File Code](#3-kiến-trúc-phần-mềm--giải-thích-chi-tiết-toàn-bộ-file-code)
   - 3.1. Sơ đồ dòng dữ liệu (Reactive Data Flow)
   - 3.2. Cấu trúc thư mục & trách nhiệm của từng file
4. [Kịch Bản Thuyết Trình Demo Từng Màn Hình (Live Demo Script)](#4-kịch-bản-thuyết-trình-demo-từng-màn-hình-live-demo-script)
5. [Bộ Câu Hỏi Vấn Đáp Bảo Vệ Đồ Án (Thầy Cô Thường Hỏi & Câu Trả Lời Chuẩn 10/10)](#5-bộ-câu-hỏi-vấn-đáp-bảo-vệ-đồ-án-thầy-cô-thường-hỏi--câu-trả-lời-chuẩn-1010)
6. [Lời Thoại Thuyết Trình Mẫu (Phân Vai: Trần Văn Hợp & Mai Tuấn An)](#6-lời-thoại-thuyết-trình-mẫu-phân-vai-trần-văn-hợp--mai-tuấn-an)

---

## 1. THÔNG TIN ĐỒ ÁN & PHÂN CÔNG NHIỆM VỤ THÀNH VIÊN

* **Tên đề tài:** Chủ đề 02: Lập trình Bất đồng bộ với Future & Stream: Xây dựng Module Reactive thời gian thực.
* **Tên sản phẩm:** **CryptoPulse Reactive Tracker**.
* **Công nghệ phát triển:** Ngôn ngữ **Dart (>= 3.0.0)** & Framework **Flutter Multi-platform** (Chạy trên Web, iOS, Android, Desktop).
* **Kho lưu trữ GitHub:** [https://github.com/vanhop05/reactive_crypto_tracker.](https://github.com/vanhop05/reactive_crypto_tracker.)

### Bảng phân công chi tiết (Work Breakdown Structure - WBS):

| Thành viên | Vai trò | Trách nhiệm & Các file mã nguồn phụ trách |
| :--- | :--- | :--- |
| **Trần Văn Hợp** | **Trưởng nhóm / Backend & Core Reactive Architecture** | - Khởi tạo dự án, thiết kế kiến trúc phân lớp Clean Architecture.<br>- Viết lõi quản lý luồng: `lib/services/crypto_price_stream_service.dart`<br>- Xây dựng phòng thí nghiệm: `lib/services/event_loop_simulator_service.dart`<br>- Định nghĩa cấu trúc dữ liệu: `lib/models/crypto_asset.dart`, `lib/models/market_tick.dart`<br>- Thiết kế theme giao diện tối: `lib/core/theme/app_theme.dart`<br>- Xây dựng màn hình: `lib/views/event_loop_lab_screen.dart`, `lib/views/architecture_guide_screen.dart`<br>- Quản lý cấu hình & Git: `pubspec.yaml`, `README.md`. |
| **Mai Tuấn An** | **Thành viên / UI/UX & Stream Transformers Specialist** | - Xây dựng các toán tử biến đổi luồng: `lib/core/transformers/stream_transformers.dart`<br>- Viết Service sổ lệnh: `lib/services/order_book_stream_service.dart`<br>- Thiết kế Models: `lib/models/order_book_entry.dart`, `lib/models/event_loop_step.dart`<br>- Xây dựng màn hình: `lib/views/crypto_market_screen.dart`, `lib/views/crypto_detail_screen.dart`, `lib/views/stream_operators_lab_screen.dart`, `lib/views/main_navigation_screen.dart`<br>- Xây dựng các Widget Reactive: `lib/widgets/price_ticker_card.dart`, `lib/widgets/mini_price_chart.dart`, `lib/widgets/order_book_widget.dart`, `lib/widgets/stream_lifecycle_badge.dart`<br>- Viết bộ Unit Test: `test/reactive_crypto_test.dart`. |

---

## 2. BẢN CHẤT KỸ THUẬT CỐT LÕI (ĐỌC ĐỂ HIỂU SÂU & THUYẾT TRÌNH)

### 2.1. Bản chất đơn luồng (Single-thread) và Event Loop trong Dart
* **Dart là ngôn ngữ đơn luồng (Single-threaded):** Tại một thời điểm, chỉ có **một tác vụ duy nhất** được CPU thực thi trong một `Isolate`.
* **Tại sao đơn luồng lại không bị đơ/lag ứng dụng?**
  Nhờ cơ chế **Event Loop (Vòng lặp sự kiện)**. Khi một tác vụ tốn thời gian (như chờ tải dữ liệu mạng, đọc ghi file, hay chờ tín hiệu timer), Dart không đứng đợi mà "gửi" tác vụ đó vào hàng đợi và tiếp tục thực hiện các dòng code đồng bộ khác. Khi có dữ liệu trả về, Event Loop sẽ bốc tác vụ đó ra xử lý tiếp.

### 2.2. Microtask Queue vs Event Queue: Cơ chế và thứ tự ưu tiên
Dart quản lý hai hàng đợi (Queue) riêng biệt:
1. **Microtask Queue:** Chứa các tác vụ nội bộ khẩn cấp của hệ thống hoặc do lập trình viên khai báo qua `scheduleMicrotask()`.
2. **Event Queue:** Chứa các sự kiện bên ngoài như: người dùng nhấn chuột (I/O event), tín hiệu Timer (`Timer.periodic`), phản hồi mạng (`Future`, `Stream`), tín hiệu vẽ khung hình (Drawing event).

> **Quy Tắc Bất Di Bất Dịch Của Event Loop:**
> 1. Code đồng bộ (Synchronous code) chạy xong 100%.
> 2. Event Loop kiểm tra **Microtask Queue** trước. Nếu có việc, xử lý cho đến khi **Microtask Queue rỗng hoàn toàn**.
> 3. Sau đó mới bốc **1 tác vụ từ Event Queue** ra xử lý.
> 4. Sau mỗi Event, Event Loop lại quay lại kiểm tra Microtask Queue.

*Trong ứng dụng, màn hình **Event Loop Lab** chứng minh trực quan 100% quy tắc này cho người xem.*

### 2.3. Phân biệt sâu sắc giữa `Future` và `Stream`
| Đặc điểm | `Future` (Tương lai) | `Stream` (Dòng chảy) |
| :--- | :--- | :--- |
| **Số lượng dữ liệu trả về** | **Duy nhất 1 giá trị** (hoặc 1 lỗi) rồi kết thúc. | **Nhiều giá trị liên tiếp** theo thời gian (0, 1 hoặc vô hạn). |
| **Ví dụ thực tế** | Lấy thông tin chi tiết của 1 Coin khi người dùng bấm vào (gọi 1 API HTTP duy nhất). | Luồng nhảy giá liên tục của Bitcoin trên sàn giao dịch (như nước chảy qua ống). |
| **Cách hứng trong Widget** | Dùng `FutureBuilder` (vẽ lại khi Future có kết quả). | Dùng `StreamBuilder` (vẽ lại mỗi khi có dữ liệu mới bắn vào Stream). |

### 2.4. Single-Subscription Stream vs Broadcast Stream
* **Single-Subscription Stream:** Luồng chỉ cho phép **duy nhất 1 đối tượng** lắng nghe (`listen`). Nếu có đối tượng thứ 2 cố lắng nghe sẽ bị báo lỗi `StateError: Stream has already been listened to`. (Ví dụ: đọc một file từ đĩa).
* **Broadcast Stream:** Luồng phát thanh công cộng, cho phép **vô số đối tượng** cùng lắng nghe một lúc mà không bị lỗi.
* **Tại sao đồ án chọn Broadcast Stream?**
  Vì luồng giá Bitcoin cần được hiển thị ở nhiều nơi cùng một lúc:
  - Thẻ coin ngoài trang chủ (`PriceTickerCard`).
  - Biểu đồ chi tiết trong màn hình con (`CryptoDetailScreen`).
  - Thanh đếm số lượng người theo dõi trên thanh tiêu đề.

### 2.5. Quản lý vòng đời Stream và Chống Thất Thoát Bộ Nhớ (Memory Leak)
* **Vấn đề:** Nếu một Widget mở kết nối lắng nghe Stream (`stream.listen(...)`), khi người dùng bấm quay lại (màn hình bị hủy) mà không ngắt kết nối, Stream vẫn tiếp tục chạy ngầm trong bộ nhớ ➔ dẫn đến **Memory Leak (rò rỉ RAM)** và crash ứng dụng.
* **Giải pháp trong đồ án:**
  1. Sử dụng widget `StreamBuilder`: Tự động đăng ký `listen()` khi hiển thị và tự động gọi `cancel()` khi Widget bị gỡ khỏi cây giao diện.
  2. Với các Subscription thủ công: Luôn lưu lại biến `StreamSubscription? _sub` và gọi `_sub?.cancel()` trong hàm `dispose()`.
  3. Lắng nghe callback `onListen` và `onCancel` ngay trên `StreamController` để theo dõi chính xác số lượng listener đang hoạt động.

### 2.6. Biến đổi dữ liệu luồng với StreamTransformer
Đồ án xây dựng các toán tử xử lý luồng nâng cao (`lib/core/transformers/stream_transformers.dart`):
* **`where(filter)`:** Lọc dữ liệu. Ví dụ chỉ bắt các bước giá của riêng đồng `BTC`, bỏ qua các đồng khác.
* **`debounce(duration)`:** Chống dội dữ liệu. Khi thị trường biến động cực nhanh (100 lệnh/giây), `debounce` giúp gom lại và chỉ cập nhật giao diện sau khi luồng ngưng nghỉ một khoảng thời gian nhất định, giúp UI không bị giật lag và tiết kiệm CPU.
* **`map(mapper)`:** Biến đổi kiểu dữ liệu của luồng (từ dữ liệu thô sang đối tượng mô hình hiển thị).

---

## 3. KIẾN TRÚC PHẦN MỀM & GIẢI THÍCH CHI TIẾT TOÀN BỘ FILE CODE

### 3.1. Cấu trúc thư mục & Giải thích từng file mã nguồn:

```text
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart               # Định nghĩa Dark/Light Theme chuẩn phong cách sàn Binance/Coinbase
│   └── transformers/
│       └── stream_transformers.dart     # Xây dựng các toán tử Reactive: debounce, whereSymbol, thresholdFilter
├── models/
│   ├── crypto_asset.dart                # Mô hình dữ liệu tiền mã hóa: Giá, thay đổi 24h, lịch sử giá sparkline
│   ├── market_tick.dart                 # Dữ liệu của 1 bước nhảy giá (symbol, giá mới, % biến động, timestamp)
│   ├── order_book_entry.dart            # Mô hình 1 dòng lệnh trong sổ lệnh (Giá, khối lượng, lệnh Mua/Bán)
│   └── event_loop_step.dart             # Mô hình bước thực thi mô phỏng trong phòng thí nghiệm Event Loop
├── services/
│   ├── crypto_price_stream_service.dart # TRÁI TIM CỦA APP: Quản lý StreamController.broadcast, sinh giá thời gian thực
│   ├── event_loop_simulator_service.dart# Mô phỏng trực quan cách Event Loop xếp hàng và bốc Microtask vs Event
│   └── order_book_stream_service.dart   # Tạo luồng cập nhật độ sâu thị trường (Order Book Bids/Asks)
├── views/
│   ├── main_navigation_screen.dart      # Thanh điều hướng chính (Bottom Navigation Bar) chuyển 4 tab
│   ├── crypto_market_screen.dart        # Tab 1: Danh sách thị trường, lọc danh mục, bộ đếm active listeners
│   ├── crypto_detail_screen.dart        # Màn hình chi tiết 1 Coin: Biểu đồ giá, bảng thống kê và sổ lệnh
│   ├── stream_operators_lab_screen.dart # Tab 2: Phòng thí nghiệm các toán tử Stream (Test debounce, filter)
│   ├── event_loop_lab_screen.dart       # Tab 3: Phòng thí nghiệm Event Loop (Nút bấm thử nghiệm thứ tự chạy)
│   └── architecture_guide_screen.dart   # Tab 4: Cẩm nang hướng dẫn kiến trúc và lý thuyết tích hợp trong app
└── widgets/
    ├── price_ticker_card.dart           # Thẻ hiển thị giá có hiệu ứng chớp màu (Xanh lá khi tăng, Đỏ khi giảm)
    ├── mini_price_chart.dart            # Vẽ đồ thị đường cong xu hướng giá (CustomPainter)
    ├── order_book_widget.dart           # Hiển thị 2 cột lệnh Mua (Xanh) và Bán (Đỏ) nhảy theo thời gian thực
    └── stream_lifecycle_badge.dart      # Huy hiệu hiển thị trạng thái luồng (ACTIVE / IDLE / PAUSED)
```

---

## 4. KỊCH BẢN THUYẾT TRÌNH DEMO TỪNG MÀN HÌNH (LIVE DEMO SCRIPT)

Khi đứng trước máy chiếu hoặc trình chiếu màn hình máy tính / iPhone:

### Màn hình 1: Thị Trường Tiền Mã Hóa (Crypto Market)
* **Thao tác:** Mở app, cho thầy cô thấy các con số giá Bitcoin, Ethereum, Solana đang tự động nhảy liên tục mà không hề bấm nút refresh hay tải lại trang.
* **Thuyết minh:** 
  > *"Thưa thầy cô, tại màn hình này, giao diện đang được điều khiển bởi một `StreamBuilder` gắn vào `CryptoPriceStreamService`. Mỗi khi có một `MarketTick` mới bắn ra từ luồng broadcast, chỉ có widget thẻ coin tương ứng được dựng lại (re-render) cục bộ, giúp tiết kiệm tối đa tài nguyên đồ họa. Khi giá tăng, thẻ sẽ nhấp nháy ánh xanh, khi giá giảm sẽ ánh đỏ."*
* **Điểm nhấn kỹ thuật:** Chỉ vào góc trên bên phải màn hình có chữ **"Active Listeners: 1"** ➔ Thể hiện khả năng giám sát vòng đời stream.

### Màn hình 2: Chi Tiết Coin & Sổ Lệnh (Crypto Detail & Order Book)
* **Thao tác:** Bấm vào đồng **Bitcoin (BTC)** để mở màn hình chi tiết.
* **Thuyết minh:** 
  > *"Khi chuyển sang màn hình chi tiết, số lượng Active Listeners lập tức tăng lên 2. Lúc này, luồng Stream được lọc qua toán tử `where((tick) => tick.symbol == 'BTC')` để chỉ cập nhật riêng dữ liệu cho Bitcoin. Bên dưới là sổ lệnh Order Book mô phỏng độ sâu thị trường thời gian thực với hai luồng Mua (Bids) và Bán (Asks) chạy song song."*
* **Thao tác chứng minh chống rò rỉ bộ nhớ:** Bấm nút **Back (Quay lại)** ➔ Số lượng Active Listeners giảm lại về 1 ➔ Chứng minh hàm `dispose()` đã tự hủy lắng nghe thành công, không để lại rác bộ nhớ!

### Màn hình 3: Phòng Thí Nghiệm Toán Tử Stream (Stream Operators Lab)
* **Thao tác:** Chuyển sang Tab 2, điều chỉnh thanh trượt tốc độ phát Stream từ **500ms** (rất nhanh) lên **2000ms** (chậm). Bật tính năng **Debounce Filter (500ms)**.
* **Thuyết minh:**
  > *"Đây là Module giúp nghiên cứu thực nghiệm các toán tử StreamTransformer. Khi nguồn phát bắn dữ liệu dồn dập, bộ lọc `debounce` sẽ trì hoãn và gom các sự kiện lại, giúp giao diện không bị giật lag."*

### Màn hình 4: Phòng Thí Nghiệm Event Loop (Event Loop Lab)
* **Thao tác:** Chuyển sang Tab 3, bấm nút **"Chạy Thử Nghiệm Mô Phỏng" (Execute Simulation)**.
* **Thuyết minh:**
  > *"Đây là module đặc sắc nhất của nhóm để làm rõ cơ chế bất đồng bộ của Dart. Khi bấm nút, một tác vụ Đồng bộ, một Microtask và một Event (Future) được kích hoạt cùng lúc. Màn hình minh họa trực quan quá trình Event Loop ưu tiên giải quyết Microtask Queue trước rồi mới bốc tác vụ trong Event Queue."*

---

## 5. BỘ CÂU HỎI VẤN ĐÁP BẢO VỆ ĐỒ ÁN (THẦY CÔ THƯỜNG HỎI & CÂU TRẢ LỜI CHUẨN 10/10)

#### ❓ Câu 1: Tại sao trong đồ án các em dùng StreamController.broadcast() mà không dùng StreamController thường?
* **Trả lời chuẩn:** 
  > *"Dạ thưa Thầy/Cô, StreamController thông thường là Single-Subscription Stream, chỉ cho phép duy nhất một listener lắng nghe. Nếu một màn hình khác (như trang Chi tiết) cố gắng lắng nghe cùng lúc, chương trình sẽ crash với lỗi StateError. Trong ứng dụng tài chính như CryptoPulse, dữ liệu giá cần được cung cấp đồng thời cho nhiều thành phần: Thẻ danh sách thị trường, Biểu đồ chi tiết, và Bộ đếm Listener ở Header. Vì vậy, nhóm em sử dụng `.broadcast()` để hỗ trợ mô hình Multi-cast (nhiều nơi cùng nghe một luồng phát)."*

#### ❓ Câu 2: Trong Flutter, việc lắng nghe Stream liên tục có gây hao pin và tốn RAM không? Nhóm đã xử lý vấn đề Memory Leak như thế nào?
* **Trả lời chuẩn:** 
  > *"Dạ có, nếu không quản lý tốt, các StreamSubscription không được đóng khi thoát màn hình sẽ tiếp tục chạy ngầm, gây rò rỉ bộ nhớ (Memory Leak) và tiêu tốn CPU. Nhóm em xử lý triệt để bằng 2 kỹ thuật:
  > 1. Ưu tiên sử dụng `StreamBuilder`: Widget này có cơ chế tự động quản lý vòng đời, tự `listen` khi mount và tự `cancel` khi unmount khỏi Widget Tree.
  > 2. Đối với các Subscription thủ công, nhóm luôn lưu vào biến và gọi phương thức `cancel()` bên trong hàm `dispose()` của State. Đồng thời kiểm tra qua callback `onCancel` của StreamController để đảm bảo khi không còn ai nghe thì luồng sẽ được giải phóng."*

#### ❓ Câu 3: Hãy giải thích sự khác biệt giữa `scheduleMicrotask` và `Timer / Future` trong Dart? Cái nào được ưu tiên hơn?
* **Trả lời chuẩn:** 
  > *"Dạ thưa Thầy/Cô, cả hai đều là bất đồng bộ, nhưng nằm ở hai hàng đợi khác nhau của Event Loop:
  > - `scheduleMicrotask` đưa công việc vào **Microtask Queue**.
  > - `Timer` hoặc `Future.delayed` đưa công việc vào **Event Queue**.
  > Event Loop của Dart có quy tắc: Luôn xử lý sạch toàn bộ công việc trong Microtask Queue trước khi bốc bất kỳ công việc nào trong Event Queue. Do đó, Microtask luôn được ưu tiên chạy trước Future."*

#### ❓ Câu 4: Dữ liệu nhảy giá trong ứng dụng này có phải từ sàn thật không? Nếu muốn nối API thật của Binance thì làm như thế nào?
* **Trả lời chuẩn:** 
  > *"Dạ thưa Thầy/Cô, giá khởi điểm được lấy chuẩn theo thị trường thế giới. Sự biến động giá được sinh bởi một Engine mô phỏng chuyển động Brown hình học chạy ngầm trong Service để đảm bảo tính sẵn sàng 100% khi demo không bị phụ thuộc vào mạng trường học hay bị dính lỗi rate-limit của sàn.
  > Nhóm em áp dụng kiến trúc Clean Architecture, tách biệt hoàn toàn Tầng Giao Diện và Tầng Dịch Vụ qua interface Stream. Nếu muốn kết nối sàn Binance thật, nhóm chỉ cần thay thế phần sinh Timer trong `crypto_price_stream_service.dart` bằng một kết nối WebSocket đến endpoint `wss://stream.binance.com:9443` mà không cần thay đổi bất kỳ một dòng code giao diện nào."*

---

## 6. LỜI THOẠI THUYẾT TRÌNH MẪU (PHÂN VAI: TRẦN VĂN HỢP & MAI TUẤN AN)

*Thời lượng khuyến nghị: 7 - 10 phút.*

### [Phút 0 - 2]: Mở đầu & Đặt vấn đề (Trần Văn Hợp)
> **Trần Văn Hợp:** 
> *"Kính chào Thầy/Cô và các bạn. Em là Trần Văn Hợp, và đi cùng em là bạn Mai Tuấn An. Hôm nay, nhóm em xin đại diện báo cáo đề tài **Chủ đề 02: Lập trình Bất đồng bộ với Future & Stream: Xây dựng Module Reactive thời gian thực**.
> 
> Trong kỷ nguyên số hiện nay, các ứng dụng tài chính như Binance, SSI hay chứng khoán đòi hỏi dữ liệu phải được cập nhật tức thời theo từng mili-giây mà không được làm đơ hay giật giao diện người dùng. Với một ngôn ngữ chạy đơn luồng (Single-thread) như Dart, làm sao để vừa xử lý hàng ngàn bước giá nhảy liên tục, vừa vẽ giao diện mượt mà 60 FPS? 
> 
> Để trả lời câu hỏi đó, nhóm em đã xây dựng sản phẩm **CryptoPulse Reactive Tracker** - ứng dụng đa nền tảng vừa theo dõi thị trường tài chính, vừa là công cụ trực quan hóa cơ chế Event Loop và Stream trong Dart."*

### [Phút 2 - 5]: Trình bày Kiến trúc Lõi & Demo Event Loop (Trần Văn Hợp)
> **Trần Văn Hợp:**
> *"Về mặt kiến trúc, em đảm nhận xây dựng tầng Lõi và Dịch vụ (Core & Service Layer). Ứng dụng sử dụng mô hình Broadcast Stream Controller để phân phối dữ liệu đa hướng.
> 
> Sau đây em xin demo màn hình **Event Loop Lab** trên máy tính:
> Khi em nhấn nút thực thi, hệ thống sẽ gọi đồng thời code Đồng bộ, Microtask và Future. Như Thầy/Cô thấy trên màn hình: Mặc dù Future được gọi trước, nhưng Dart Event Loop luôn ưu tiên chạy hết tác vụ trong Microtask Queue rồi mới xử lý Event Queue. Điều này chứng minh bản chất bất đồng bộ không phải là đa luồng chạy song song của hệ điều hành, mà là cơ chế luân chuyển hàng đợi thông minh."*

### [Phút 5 - 8]: Trình bày UI/UX, Sổ Lệnh & Toán Tử Stream (Mai Tuấn An)
> **Mai Tuấn An:**
> *"Tiếp nối phần kiến trúc của bạn Hợp, em là Mai Tuấn An, đảm nhận vai trò thiết kế các toán tử biến đổi luồng và xây dựng tầng giao diện phản ứng (Reactive UI).
> 
> Em xin phép chuyển sang màn hình **Thị Trường Crypto**:
> Toàn bộ thẻ giá Thầy/Cô đang thấy đều được gắn với `StreamBuilder`. Khi em bấm vào chi tiết đồng Bitcoin, thẻ mở ra biểu đồ mini và Sổ lệnh Order Book với các lệnh Mua (Bids) và Bán (Asks) nhảy liên tục. 
> 
> Điểm đặc biệt là ở góc trên: Nhóm em tích hợp **Stream Lifecycle Tracker**. Khi vào trang chi tiết, bộ đếm tăng lên 2 listeners; khi em bấm quay lại trang chủ, hàm `dispose()` được gọi và số listener giảm ngay về 1. Điều này đảm bảo ứng dụng hoàn toàn không bị rò rỉ bộ nhớ (Zero Memory Leak).
> 
> Ở tab **Stream Operators Lab**, em đã triển khai toán tử `debounce`. Khi dữ liệu từ sàn đổ về quá nhanh, `debounce` sẽ tự động gom các bước giá lại, giảm tải việc vẽ lại giao diện không cần thiết, giúp app đạt hiệu năng 60 FPS ngay cả trên các thiết bị cấu hình yếu."*

### [Phút 8 - 10]: Kết luận & Lời cảm ơn (Cả 2 thành viên)
> **Trần Văn Hợp:**
> *"Qua đồ án này, nhóm em không chỉ tạo ra một ứng dụng hoàn chỉnh có thể chạy được trên cả Web, Windows và điện thoại di động, mà quan trọng hơn là đã làm chủ hoàn toàn cơ chế Lập trình Bất đồng bộ trong Dart từ lý thuyết đến thực hành."*
>
> **Mai Tuấn An:**
> *"Nhóm em xin chân thành cảm ơn Thầy/Cô đã lắng nghe. Chúng em rất mong nhận được những câu hỏi và đóng góp quý báu từ Thầy/Cô!"*
