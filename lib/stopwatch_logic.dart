import 'dart:async';

class StopwatchLogic {
  // Sử dụng class Stopwatch của Dart để đo thời gian chính xác, không bị trễ
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  // StreamController quản lý luồng dữ liệu thời gian (tính bằng mili-giây)
  final StreamController<int> _timeController = StreamController<int>();

  Stream<int> get timeStream => _timeController.stream;

  StopwatchLogic() {
    // Phát giá trị ban đầu để giao diện hiển thị 00:00.00 ngay lập tức.
    _timeController.sink.add(0);
  }

  void start() {
    // Bỏ qua yêu cầu bắt đầu nếu đồng hồ đã đang chạy.
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    // Chạy Timer mỗi 10 mili-giây để giao diện cập nhật liên tục và mượt mà
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _timeController.sink.add(_stopwatch.elapsedMilliseconds);
    });
  }

  void pause() {
    // Dừng đồng hồ và hủy cập nhật để giữ nguyên giá trị cuối cùng.
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    _timer?.cancel();
  }

  void reset() {
    // Đặt lại cả thời gian đo được và giá trị đang hiển thị trên giao diện.
    pause();
    _stopwatch.reset();
    _timeController.sink.add(0);
  }

  // Chuyển đổi mili-giây thành định dạng MM:SS.ms (lấy 2 chữ số của mili-giây)
  String formatTime(int totalMilliseconds) {
    int hundreds = (totalMilliseconds ~/ 10) % 100; // phần trăm giây (centiseconds)
    int seconds = (totalMilliseconds ~/ 1000) % 60;
    int minutes = totalMilliseconds ~/ (1000 * 60);

    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');
    String hundredsStr = hundreds.toString().padLeft(2, '0');

    return '$minutesStr:$secondsStr.$hundredsStr';
  }

  void dispose() {
    // Giải phóng timer và đóng stream khi màn hình bị hủy.
    _timer?.cancel();
    _timeController.close();
  }
}
