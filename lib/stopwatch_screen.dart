import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'stopwatch_logic.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({Key? key}) : super(key: key);

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  // Đối tượng xử lý quản lý timer và stream của màn hình này.
  final StopwatchLogic _logic = StopwatchLogic();

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder dựng lại phần hiển thị khi nhận được giá trị mới.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bấm Giờ', style: TextStyle(color: AppColors.textColor)),
        backgroundColor: AppColors.bgColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<int>(
              stream: _logic.timeStream,
              initialData: 0,
              builder: (context, snapshot) {
                // Dùng 0 làm giá trị mặc định an toàn khi stream chưa có dữ liệu.
                final currentMilliseconds = snapshot.data ?? 0;
                return Text(
                  _logic.formatTime(currentMilliseconds),
                  style: const TextStyle(
                    fontSize: 65, // Giảm từ 80 xuống 65 để vừa chuỗi thời gian dài hơn
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentColor,
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(label: 'Bắt đầu', onPressed: _logic.start),
                const SizedBox(width: 15),
                _buildButton(label: 'Tạm dừng', onPressed: _logic.pause),
                const SizedBox(width: 15),
                _buildButton(label: 'Đặt lại', onPressed: _logic.reset),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required VoidCallback onPressed}) {
    // Tái sử dụng một kiểu nút thống nhất cho các thao tác của đồng hồ.
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonColor,
        foregroundColor: AppColors.textColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
