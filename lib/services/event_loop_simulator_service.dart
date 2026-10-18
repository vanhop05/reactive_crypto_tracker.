import 'dart:async';
import 'package:flutter/material.dart';
import '../models/event_loop_step.dart';

/// Dịch vụ mô phỏng cơ chế Event Loop, Hàng đợi Microtask (Microtask Queue) và Hàng đợi Sự kiện (Event Queue) trong Dart.
/// Ghi lại chính xác thứ tự thực thi và cung cấp nhật ký từng bước cho mục đích trực quan hóa.
class EventLoopSimulatorService {
  final StreamController<List<EventLoopStep>> _stepsController =
      StreamController<List<EventLoopStep>>.broadcast();

  Stream<List<EventLoopStep>> get stepsStream => _stepsController.stream;

  final List<EventLoopStep> _recordedSteps = [];
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  int _orderCounter = 0;
  Stopwatch? _stopwatch;

  void _record({
    required String queueType,
    required String label,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    _orderCounter++;
    final elapsedMicros = _stopwatch?.elapsedMicroseconds ?? 0;
    
    final step = EventLoopStep(
      id: _orderCounter,
      queueType: queueType,
      label: label,
      description: description,
      order: _orderCounter,
      timestampMicroseconds: elapsedMicros,
      tagColor: color,
      icon: icon,
    );

    _recordedSteps.add(step);
    _stepsController.add(List.unmodifiable(_recordedSteps));
  }

  // =========================================================================
  // [YÊU CẦU 1]: EVENT LOOP & MICROTASK QUEUE - THỰC NGHIỆM THỨ TỰ ƯU TIÊN
  // Quy tắc vàng: Mã Đồng Bộ -> Microtask Queue -> Event Queue (Future / Timer)
  // =========================================================================
  Future<void> runExperiment() async {
    if (_isRunning) return;
    _isRunning = true;
    _recordedSteps.clear();
    _orderCounter = 0;
    _stepsController.add([]);
    _stopwatch = Stopwatch()..start();

    // 1. Ngăn xếp Đồng bộ (Synchronous Stack) - Bắt đầu
    _record(
      queueType: 'Synchronous Stack',
      label: 'Main Call Stack (Start)',
      description: 'Mã đồng bộ được thực thi trực tiếp trên Call Stack ngay lập tức.',
      color: Colors.blueAccent,
      icon: Icons.flash_on,
    );

    // 2. Lên lịch tác vụ Future vào Event Queue
    Future(() {
      _record(
        queueType: 'Event Queue',
        label: 'Future() #1',
        description: 'Được đẩy vào Event Queue. Chỉ chạy SAU KHI toàn bộ Microtask Queue trống rỗng.',
        color: Colors.amber,
        icon: Icons.hourglass_top,
      );
    });

    // 3. Lên lịch tác vụ Timer có độ trễ vào Event Queue
    Future.delayed(const Duration(milliseconds: 30), () {
      _record(
        queueType: 'Event Queue (Timer)',
        label: 'Future.delayed(30ms)',
        description: 'Timer event được kích hoạt sau khi hết thời gian chờ và Event Loop nhàn rỗi.',
        color: Colors.orangeAccent,
        icon: Icons.timer,
      );
    });

    // 4. Lên lịch Microtask #1 vào Microtask Queue
    scheduleMicrotask(() {
      _record(
        queueType: 'Microtask Queue',
        label: 'scheduleMicrotask() #1',
        description: 'Được đưa vào Microtask Queue. Ưu tiên chạy TRƯỚC mọi Future trong Event Queue!',
        color: Colors.pinkAccent,
        icon: Icons.priority_high,
      );
    });

    // 5. Lên lịch Microtask #2 (Future.microtask)
    Future.microtask(() {
      _record(
        queueType: 'Microtask Queue',
        label: 'Future.microtask() #2',
        description: 'Microtask thứ 2 tiếp tục được rút và xử lý từ Microtask Queue.',
        color: Colors.purpleAccent,
        icon: Icons.bolt,
      );
    });

    // 6. Lên lịch Future #2 vào Event Queue
    Future(() {
      _record(
        queueType: 'Event Queue',
        label: 'Future() #2',
        description: 'Future thứ 2 được thực thi sau khi Microtask Queue đã được dọn sạch hoàn toàn.',
        color: Colors.amberAccent,
        icon: Icons.layers,
      );
    });

    // 7. Ngăn xếp Đồng bộ (Synchronous Stack) - Kết thúc
    _record(
      queueType: 'Synchronous Stack',
      label: 'Main Call Stack (End)',
      description: 'Mã đồng bộ kết thúc. Call Stack trống, nhường quyền cho Microtask Queue chạy.',
      color: Colors.blueAccent,
      icon: Icons.check_circle_outline,
    );

    // Đợi cho đến khi tất cả các tác vụ bất đồng bộ hoàn thành
    await Future.delayed(const Duration(milliseconds: 60));
    _stopwatch?.stop();
    _isRunning = false;
  }

  /// Xóa sạch kết quả thí nghiệm trước đó
  void clear() {
    _recordedSteps.clear();
    _stepsController.add([]);
    _isRunning = false;
  }

  void dispose() {
    if (!_stepsController.isClosed) {
      _stepsController.close();
    }
  }
}
