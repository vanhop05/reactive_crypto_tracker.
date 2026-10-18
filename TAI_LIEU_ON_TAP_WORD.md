# TÀI LIỆU ÔN TẬP & TRA CỨU MÃ NGUỒN ĐỒ ÁN
## CHỦ ĐỀ 02: LẬP TRÌNH BẤT ĐỒNG BỘ VỚI FUTURE & STREAM: XÂY DỰNG MODULE REACTIVE THỜI GIAN THỰC
**Dự án:** CryptoPulse Reactive Tracker  
**Nhóm sinh viên thực hiện:** Trần Văn Hợp & Mai Tuấn An  

---

# PHẦN 1: BẢNG TRA CỨU NHANH (VỊ TRÍ CODE TRONG ĐỒ ÁN)

Khi Thầy/Cô yêu cầu: *"Em hãy mở code và chỉ ra nội dung này nằm ở đâu trong dự án?"*, bạn chỉ cần mở đúng các file và dòng tương ứng dưới đây:

| STT | Nội dung kỹ thuật yêu cầu | File chứa mã nguồn | Vị trí dòng code cụ thể | Màn hình hiển thị trên App |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Event Loop & Microtask Queue** | • [`lib/main.dart`](file:///D:/reactive_crypto_tracker/lib/main.dart)<br>• [`lib/services/event_loop_simulator_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/event_loop_simulator_service.dart)<br>• [`test/event_loop_order_test.dart`](file:///D:/reactive_crypto_tracker/test/event_loop_order_test.dart) | • `main.dart`: Dòng 22 - 24<br>• `event_loop_simulator_service.dart`: Dòng 47 - 132 | **Tab 3:** Phòng Thí Nghiệm Event Loop (`event_loop_lab_screen.dart`) |
| **2** | **Future & async / await** | • [`lib/services/crypto_price_stream_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/crypto_price_stream_service.dart)<br>• [`lib/services/event_loop_simulator_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/event_loop_simulator_service.dart) | • `crypto_price_stream_service.dart`: Dòng 263, 369, 378<br>• `event_loop_simulator_service.dart`: Dòng 65, 76, 129 | Nút bấm **BINANCE LIVE** trên thanh tiêu đề (`AppBar`) |
| **3** | **Cơ chế Stream & StreamController** | • [`lib/services/crypto_price_stream_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/crypto_price_stream_service.dart)<br>• [`lib/services/order_book_stream_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/order_book_stream_service.dart)<br>• [`lib/views/crypto_market_screen.dart`](file:///D:/reactive_crypto_tracker/lib/views/crypto_market_screen.dart) | • `crypto_price_stream_service.dart`: Dòng 35, 41, 49, 68 - 80<br>• `order_book_stream_service.dart`: Dòng 9, 17, 71<br>• `crypto_market_screen.dart`: Dòng 24, 38 | Huy hiệu **Broadcasting / Active Listeners** trên Header |
| **4** | **Broadcast Stream (Phát đa hướng)** | • [`lib/services/crypto_price_stream_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/crypto_price_stream_service.dart)<br>• [`lib/views/crypto_market_screen.dart`](file:///D:/reactive_crypto_tracker/lib/views/crypto_market_screen.dart)<br>• [`lib/views/crypto_detail_screen.dart`](file:///D:/reactive_crypto_tracker/lib/views/crypto_detail_screen.dart) | • Khởi tạo: `crypto_price_stream_service.dart` Dòng 68<br>• Nghe ở Trang chủ: `crypto_market_screen.dart` Dòng 176<br>• Nghe ở Trang chi tiết: `crypto_detail_screen.dart` Dòng 83 | Danh sách thị trường & Màn hình Chi tiết Coin cùng nhảy giá |
| **5** | **Các toán tử biến đổi dữ liệu (Transform, Debounce, Throttle, Where)** | • [`lib/core/transformers/stream_transformers.dart`](file:///D:/reactive_crypto_tracker/lib/core/transformers/stream_transformers.dart)<br>• [`lib/views/crypto_market_screen.dart`](file:///D:/reactive_crypto_tracker/lib/views/crypto_market_screen.dart)<br>• [`lib/views/crypto_detail_screen.dart`](file:///D:/reactive_crypto_tracker/lib/views/crypto_detail_screen.dart)<br>• [`lib/services/crypto_price_stream_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/crypto_price_stream_service.dart) | • Định nghĩa: Toàn bộ file `stream_transformers.dart`<br>• Debounce 400ms: `crypto_market_screen.dart` Dòng 38 - 47<br>• Throttle 300ms: `crypto_detail_screen.dart` Dòng 85<br>• Where: `crypto_price_stream_service.dart` Dòng 253 - 255 | • Ô tìm kiếm Coin (Debounce)<br>• **Tab 2:** Phòng Thí Nghiệm Toán Tử (`stream_operators_lab_screen.dart`) |

---

# PHẦN 2: CHI TIẾT TỪNG NỘI DUNG ĐỂ HỌC VÀ TRẢ LỜI VẤN ĐÁP

---

## NỘI DUNG 1: EVENT LOOP & MICROTASK QUEUE

### 1.1. Bản chất lý thuyết (Cần học thuộc):
* **Dart là ngôn ngữ đơn luồng (Single-threaded):** Trong một `Isolate`, tại một thời điểm chỉ có 1 tác vụ được CPU xử lý trên **Call Stack**.
* Để không bị đứng máy khi xử lý việc nặng hay chờ mạng, Dart sử dụng cơ chế **Event Loop** điều phối 2 hàng đợi:
  1. **Microtask Queue:** Chứa các tác vụ khẩn cấp nội bộ (được gọi qua `scheduleMicrotask()` hoặc `Future.microtask()`).
  2. **Event Queue:** Chứa các sự kiện bên ngoài như: người dùng chạm màn hình (I/O), sự kiện Timer (`Timer.periodic`), phản hồi mạng (`Future`, `Stream`).
* **Quy tắc vàng của Event Loop:**
  $$\text{Mã Đồng Bộ (Call Stack)} \longrightarrow \text{Hút cạn sạch Microtask Queue} \longrightarrow \text{Bốc 1 Event từ Event Queue}$$
  *Event Loop luôn luôn ưu tiên chạy hết toàn bộ Microtask Queue trước khi chạm tới Event Queue!*

### 1.2. Vị trí trong Code của Đồ án:
* **Tại [`lib/main.dart`](file:///D:/reactive_crypto_tracker/lib/main.dart#L21-L24):**
  ```dart
  // Minh họa khởi tạo Microtask trong Event Loop khi ứng dụng vừa bật lên
  scheduleMicrotask(() {
    debugPrint('[EVENT_LOOP] Microtask được thực thi trong quá trình khởi động ứng dụng.');
  });
  ```
* **Tại [`lib/services/event_loop_simulator_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/event_loop_simulator_service.dart#L47-L126):**
  Hàm `runExperiment()` lên lịch cùng lúc:
  1. Mã đồng bộ `Synchronous Stack (Start)`.
  2. Sự kiện `Future()` đưa vào **Event Queue**.
  3. `scheduleMicrotask()` đưa vào **Microtask Queue**.
  4. Mã đồng bộ `Synchronous Stack (End)`.

### 1.3. Cách trả lời Thầy/Cô khi được hỏi:
> *"Dạ thưa Thầy/Cô, nhóm em chứng minh cơ chế Event Loop trực quan tại **Tab 'Phòng Thí Nghiệm Event Loop'**. Khi bấm nút chạy, Thầy Cô sẽ thấy mã Đồng bộ chạy đầu tiên, tiếp theo là Microtask Queue dù được gọi sau nhưng vẫn được Event Loop ưu tiên giải quyết sạch sẽ trước, rồi cuối cùng các Future trong Event Queue mới được thực thi."*

---

## NỘI DUNG 2: FUTURE & ASYNC / AWAIT

### 2.1. Bản chất lý thuyết (Cần học thuộc):
* **`Future<T>`:** Đại diện cho **duy nhất một giá trị (hoặc một ngoại lệ)** sẽ xuất hiện trong tương lai sau một khoảng thời gian chờ đợi.
* **`async`:** Đánh dấu một hàm là bất đồng bộ và luôn trả về một `Future`.
* **`await`:** Tạm dừng việc thực thi hàm `async` hiện tại cho đến khi `Future` hoàn tất, nhưng **không hề làm block luồng chính** của giao diện người dùng.

### 2.2. Vị trí trong Code của Đồ án:
* **Tại [`lib/services/crypto_price_stream_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/crypto_price_stream_service.dart#L263):**
  ```dart
  /// Mở kết nối WebSocket thời gian thực tới sàn Binance
  Future<void> connectToBinance() async {
    pauseSimulation();
    // ...
  }
  
  /// Chuyển đổi qua lại giữa Mô Phỏng và Binance Live WebSocket
  Future<void> toggleDataSource() async {
    if (_currentMode == DataSourceMode.simulation) {
      await connectToBinance();
    } else {
      switchToSimulation();
    }
  }
  ```
* **Tại [`lib/services/event_loop_simulator_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/event_loop_simulator_service.dart#L129):**
  ```dart
  // Đợi cho đến khi tất cả các tác vụ bất đồng bộ hoàn thành
  await Future.delayed(const Duration(milliseconds: 60));
  ```

### 2.3. Cách trả lời Thầy/Cô khi được hỏi:
> *"Dạ thưa Thầy/Cô, nhóm em sử dụng `async/await` ở các tác vụ chỉ cần thực hiện 1 lần và có độ trễ, tiêu biểu như hàm `toggleDataSource()` để kết nối máy chủ WebSocket của Binance hoặc hàm `dispose()` để giải phóng bộ nhớ. Trong khi `Future` chỉ trả về 1 kết quả duy nhất thì luồng giá liên tục của sàn lại được xử lý bằng `Stream`."*

---

## NỘI DUNG 3: CƠ CHẾ STREAM & STREAMCONTROLLER

### 3.1. Bản chất lý thuyết (Cần học thuộc):
* **`Stream`:** Là một **dòng chảy dữ liệu bất đồng bộ liên tục** (chứa 0, 1 hoặc vô số sự kiện theo thời gian). Giống như một đường ống dẫn nước, dữ liệu đi vào đầu này và chảy ra ở đầu kia.
* **`StreamController`:** Là công cụ quản lý luồng, đóng vai trò cả 2 đầu:
  - Đầu vào (`Sink`): Dùng `controller.add(data)` để đẩy dữ liệu mới vào luồng.
  - Đầu ra (`Stream`): Dùng `controller.stream` để cho các Widget bên ngoài `listen` (lắng nghe).
* **Quản lý vòng đời Stream:** `StreamController` cung cấp các callback `onListen` (khi có người nghe) và `onCancel` (khi không còn ai nghe) giúp kiểm soát tài nguyên và chống thất thoát bộ nhớ (Memory Leak).

### 3.2. Vị trí trong Code của Đồ án:
* **Khởi tạo và cấu hình vòng đời tại [`lib/services/crypto_price_stream_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/crypto_price_stream_service.dart#L35-L80):**
  ```dart
  late StreamController<MarketTick> _priceStreamController;
  
  void _initBroadcastController() {
    _priceStreamController = StreamController<MarketTick>.broadcast(
      onListen: () {
        _activeListenersCount++;
        _listenerTrackerController.add(_activeListenersCount);
      },
      onCancel: () {
        if (_activeListenersCount > 0) _activeListenersCount--;
        _listenerTrackerController.add(_activeListenersCount);
      },
    );
  }
  ```
* **Đẩy dữ liệu vào luồng tại dòng 248 và dòng 342:**
  ```dart
  _priceStreamController.add(tick); // Bắn dữ liệu giá mới cho toàn bộ ứng dụng
  ```
* **Quản lý luồng sổ lệnh tại [`lib/services/order_book_stream_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/order_book_stream_service.dart#L9-L21):**
  Sử dụng `StreamController<List<OrderBookEntry>>` để sinh dữ liệu sổ lệnh Mua/Bán mỗi 900ms.

---

## NỘI DUNG 4: BROADCAST STREAM (PHÁT ĐA HƯỚNG)

### 4.1. Bản chất lý thuyết (Cần học thuộc):
* **Single-Subscription Stream (Mặc định):** Chỉ cho phép duy nhất **1 đối tượng** lắng nghe. Nếu có đối tượng thứ 2 cố lắng nghe sẽ báo lỗi `StateError: Stream has already been listened to`. (Ví dụ: đọc file từ ổ cứng).
* **Broadcast Stream (`StreamController.broadcast()`):** Cho phép **nhiều đối tượng độc lập** cùng lắng nghe một luồng dữ liệu mà không gây xung đột. Các đối tượng có thể tự do kết nối hoặc ngắt kết nối mà không ảnh hưởng tới đối tượng khác.

### 4.2. Vị trí trong Code của Đồ án:
* **Khởi tạo Broadcast Stream:**
  Tại [`lib/services/crypto_price_stream_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/crypto_price_stream_service.dart#L68):
  ```dart
  _priceStreamController = StreamController<MarketTick>.broadcast(...);
  ```
* **Đối tượng 1 lắng nghe (Trang chủ thị trường):**
  Tại [`lib/views/crypto_market_screen.dart`](file:///D:/reactive_crypto_tracker/lib/views/crypto_market_screen.dart#L176):
  ```dart
  body: StreamBuilder<MarketTick>(
    stream: service.marketStream, // Lắng nghe để cập nhật danh sách giá coin
    builder: (context, snapshot) { ... }
  )
  ```
* **Đối tượng 2 lắng nghe (Trang chi tiết coin):**
  Tại [`lib/views/crypto_detail_screen.dart`](file:///D:/reactive_crypto_tracker/lib/views/crypto_detail_screen.dart#L83-L86):
  ```dart
  _tickSubscription = CryptoPriceStreamService.instance
      .getStreamForSymbol(_asset.symbol)
      .listen((tick) { ... }); // Lắng nghe đồng thời để cập nhật biểu đồ chi tiết!
  ```

### 4.3. Cách trả lời Thầy/Cô khi được hỏi:
> *"Dạ thưa Thầy/Cô, trong ứng dụng tài chính CryptoPulse, giá của Bitcoin vừa phải hiển thị ở thẻ danh sách ngoài trang chủ, vừa phải vẽ biểu đồ ở trang chi tiết, vừa phải phục vụ bộ đếm Listener ở Header. Nếu dùng Stream thông thường thì ứng dụng sẽ crash ngay lập tức. Do đó, nhóm em bắt buộc phải cấu hình `StreamController.broadcast()` để hỗ trợ mô hình Multi-cast này."*

---

## NỘI DUNG 5: CÁC TOÁN TỬ BIẾN ĐỔI DỮ LIỆU (TRANSFORM, DEBOUNCE, THROTTLE, WHERE)

### 5.1. Bản chất lý thuyết (Cần học thuộc):
* **Toán tử `where` (Lọc):** Chỉ cho phép các phần tử thỏa mãn điều kiện đi qua.
* **Toán tử `debounce` (Chống dội):** Trì hoãn việc phát sự kiện. Chỉ khi nào nguồn phát **ngừng bắn dữ liệu** trong một khoảng thời gian nhất định (ví dụ 400ms) thì mới phát sự kiện cuối cùng. Rất hữu ích cho ô tìm kiếm để tránh gửi request liên tục khi người dùng đang gõ.
* **Toán tử `throttle` (Tiết lưu):** Phát sự kiện đầu tiên ngay lập tức, sau đó **chặn toàn bộ** các sự kiện tiếp theo trong một khoảng thời gian (ví dụ 300ms). Rất hữu ích khi thị trường nhảy 100 lần/giây, giúp UI chỉ vẽ lại tối đa 3 lần/giây, tránh nghẽn GPU.

### 5.2. Vị trí trong Code của Đồ án:
* **Bộ chuyển đổi tùy chỉnh tại [`lib/core/transformers/stream_transformers.dart`](file:///D:/reactive_crypto_tracker/lib/core/transformers/stream_transformers.dart):**
  - Lớp `DebounceStreamTransformer<T>`: Dòng 5 - 61 (Quản lý `Timer` hủy và tạo mới).
  - Lớp `ThrottleStreamTransformer<T>`: Dòng 65 - 117 (Quản lý biến cờ `isThrottled`).
  - Cung cấp cú pháp tiện dụng mở rộng qua extension: `.debounce()` và `.throttle()`.
* **Áp dụng Debounce 400ms ở ô Tìm kiếm:**
  Tại [`lib/views/crypto_market_screen.dart`](file:///D:/reactive_crypto_tracker/lib/views/crypto_market_screen.dart#L38-L47):
  ```dart
  _searchSubscription = _searchQueryController.stream
      .debounce(const Duration(milliseconds: 400))
      .listen((query) {
        setState(() {
          _currentQuery = query.trim().toLowerCase();
        });
      });
  ```
* **Áp dụng Throttle 300ms ở Trang chi tiết:**
  Tại [`lib/views/crypto_detail_screen.dart`](file:///D:/reactive_crypto_tracker/lib/views/crypto_detail_screen.dart#L83-L86):
  ```dart
  _tickSubscription = CryptoPriceStreamService.instance
      .getStreamForSymbol(_asset.symbol)
      .throttle(const Duration(milliseconds: 300))
      .listen((tick) { ... });
  ```
* **Áp dụng Where để lọc theo mã Symbol:**
  Tại [`lib/services/crypto_price_stream_service.dart`](file:///D:/reactive_crypto_tracker/lib/services/crypto_price_stream_service.dart#L253-L255):
  ```dart
  Stream<MarketTick> getStreamForSymbol(String symbol) {
    return marketStream.where((tick) => tick.symbol.toUpperCase() == symbol.toUpperCase());
  }
  ```

---

# PHẦN 3: KỊCH BẢN THỰC HÀNH "CHỈ TAY VÀO MÀN HÌNH" TRƯỚC HỘI ĐỒNG

Khi Thầy Cô yêu cầu: *"Bây giờ em hãy thực hiện demo chứng minh 5 nội dung này ngay trên phần mềm đang chạy!"*, các bạn làm theo 4 bước sau:

* **Bước 1 (Chứng minh Stream & Broadcast):** 
  - Mở trang chủ thấy số nhảy liên tục không cần reload ➔ Giải thích: *"Đây là Stream"* (Dòng 176 `crypto_market_screen.dart`).
  - Bấm vào chi tiết đồng Bitcoin ➔ Thấy cả 2 nơi cùng nhảy giá ➔ Giải thích: *"Đây là Broadcast Stream"* (Dòng 68 `crypto_price_stream_service.dart`).
* **Bước 2 (Chứng minh Debounce):**
  - Tại ô tìm kiếm trang chủ, gõ nhanh chữ `B-I-T-C-O-I-N`.
  - Chỉ cho Thầy Cô thấy: Trong lúc tay đang gõ thì vòng quay tròn nhỏ xuất hiện, app không lọc ngay mà chờ đúng **400ms** sau khi tay dừng gõ mới lọc ➔ Giải thích: *"Đây là toán tử Debounce giúp chống nghẽn UI"* (Dòng 39 `crypto_market_screen.dart`).
* **Bước 3 (Chứng minh Event Loop & Microtask):**
  - Chuyển sang **Tab 3: Phòng Thí Nghiệm Event Loop**.
  - Nhấn nút **"Chạy Thử Nghiệm Mô Phỏng"**.
  - Chỉ vào danh sách kết quả: Mã đồng bộ đứng số 1 và 2, Microtask đứng số 3 và 4, còn Future đứng số 5 và 6 ➔ Giải thích: *"Minh chứng Event Loop ưu tiên Microtask Queue trước Event Queue"* (File `event_loop_simulator_service.dart`).
* **Bước 4 (Chứng minh Kết nối API Thực tế):**
  - Bấm vào nút **BINANCE LIVE** màu vàng trên góc phải màn hình ➔ Giá nhảy theo sàn Binance thế giới thật 100% ➔ Giải thích: *"Đây là WebSocket và Future bất đồng bộ"* (Dòng 263 `crypto_price_stream_service.dart`).
