import 'package:flutter/material.dart';

/// Screen displaying the complete technical documentation and architectural reference for Topic 02.
class ArchitectureGuideScreen extends StatelessWidget {
  const ArchitectureGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiến Trúc & Hướng Dẫn Kỹ Thuật'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            context,
            title: '1. Event Loop & Microtask Queue',
            icon: Icons.sync,
            color: const Color(0xFF06B6D4),
            content:
                '• Dart là ngôn ngữ đơn luồng (Single-threaded) có Event Loop.\n'
                '• Microtask Queue: Chứa các tác vụ nội bộ khẩn cấp (scheduleMicrotask, Future.microtask). Event Loop LUÔN chạy sạch Microtask Queue trước khi lấy sự kiện tiếp theo từ Event Queue.\n'
                '• Event Queue: Chứa I/O, gesture events, Timer, và Future thông thường.\n'
                '• Quy tắc vàng: Không đưa tác vụ tính toán nặng vào Microtask Queue để tránh làm treo UI (Frame freeze).',
          ),
          const SizedBox(height: 12),
          _buildCard(
            context,
            title: '2. Single-Subscription vs Broadcast Stream',
            icon: Icons.stream,
            color: const Color(0xFF10B981),
            content:
                '• Single-Subscription Stream: Chỉ cho phép DUY NHẤT một listener tại một thời điểm (ví dụ: File I/O stream, HTTP response). Lắng nghe lần 2 sẽ văng lỗi StateError.\n'
                '• Broadcast Stream (StreamController.broadcast()): Cho phép NHIỀU listener đồng thời (ví dụ: Market price stream, WebSocket feed, bus event). Khi widget thoát màn hình, hủy subscription mà không ảnh hưởng listener khác.',
          ),
          const SizedBox(height: 12),
          _buildCard(
            context,
            title: '3. An Toàn Bộ Nhớ & Hủy Luồng (Dispose)',
            icon: Icons.shield,
            color: const Color(0xFFEF4444),
            content:
                '• Vấn đề: Nếu tạo StreamSubscription trong StatefulWidget mà không hủy, Stream sẽ tiếp tục gửi sự kiện vào widget đã chết (Zombie listener) gây rò rỉ RAM và lỗi setState() after dispose().\n'
                '• Giải pháp bắt buộc:\n'
                '   @override\n'
                '   void dispose() {\n'
                '     _subscription?.cancel();\n'
                '     _controller.close();\n'
                '     super.dispose();\n'
                '   }',
          ),
          const SizedBox(height: 12),
          _buildCard(
            context,
            title: '4. Toán Tử Debounce & Throttle',
            icon: Icons.filter_alt,
            color: const Color(0xFF8B5CF6),
            content:
                '• Debounce: Chờ một khoảng thời gian yên tĩnh (quiet period) sau sự kiện cuối cùng mới phát. Dùng cho ô tìm kiếm, auto-save.\n'
                '• Throttle: Giới hạn tần suất phát sự kiện (ví dụ tối đa 1 lần mỗi 500ms). Dùng cho nút bấm double-click, scroll event, high-frequency price ticks.',
          ),
          const SizedBox(height: 12),
          _buildCard(
            context,
            title: '5. Triển Khai Đa Nền Tảng (Android & iOS)',
            icon: Icons.devices,
            color: const Color(0xFFF59E0B),
            content:
                '• Android: Chạy trực tiếp trên điện thoại cắm dây USB (Bật USB Debugging) hoặc Android Emulator qua lệnh:\n'
                '   flutter run -d android\n'
                '• iOS: Chạy trên iOS Simulator hoặc iPhone thật qua lệnh:\n'
                '   flutter run -d ios\n'
                '• Web: flutter run -d chrome\n'
                '• Windows Desktop: flutter run -d windows',
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(fontSize: 12, color: Colors.grey[300], height: 1.5),
          ),
        ],
      ),
    );
  }
}
