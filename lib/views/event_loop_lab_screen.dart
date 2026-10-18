import 'package:flutter/material.dart';
import '../models/event_loop_step.dart';
import '../services/event_loop_simulator_service.dart';

/// Màn hình phòng thí nghiệm tương tác minh họa trực quan cơ chế Dart Event Loop,
/// thứ tự thực thi giữa Microtask Queue và Event Queue.
class EventLoopLabScreen extends StatefulWidget {
  const EventLoopLabScreen({super.key});

  @override
  State<EventLoopLabScreen> createState() => _EventLoopLabScreenState();
}

class _EventLoopLabScreenState extends State<EventLoopLabScreen> {
  final EventLoopSimulatorService _simulatorService = EventLoopSimulatorService();

  @override
  void dispose() {
    _simulatorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng Thí Nghiệm Event Loop'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ hiển thị tóm tắt kiến trúc Event Loop trực quan, đơn giản
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.hub_outlined, color: Color(0xFF06B6D4), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Cơ Chế Dart Event Loop & Thứ Tự Hàng Đợi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quy tắc ưu tiên: Mã đồng bộ chạy ngay ➔ Hút cạn Microtask Queue ➔ Xử lý Event Queue.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 14),
                  _buildQueueFlowDiagram(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Thẻ điều khiển thực nghiệm
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thực Nghiệm Thứ Tự Ưu Tiên',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kiểm chứng Microtask Queue luôn chạy trước Event Queue dù khai báo sau.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('Chạy Thử', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      _simulatorService.runExperiment();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Nhật Ký Thực Thi Thời Gian Thực (Execution Log):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Dòng dữ liệu hiển thị nhật ký thực thi trực tiếp
            StreamBuilder<List<EventLoopStep>>(
              stream: _simulatorService.stepsStream,
              initialData: const [],
              builder: (context, snapshot) {
                final steps = snapshot.data ?? [];

                if (steps.isEmpty) {
                  return Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.terminal, color: Colors.grey[500], size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn "Chạy Thử" để ghi lại trình tự Event Loop',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: step.tagColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: step.tagColor.withOpacity(0.2),
                              border: Border.all(color: step.tagColor),
                            ),
                            child: Center(
                              child: Text(
                                '#${step.order}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: step.tagColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      step.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: step.tagColor,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: step.tagColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        step.queueType,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: step.tagColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  step.description,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Độ trễ: +${step.timestampMicroseconds} µs',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Sơ đồ luồng hàng đợi Event Loop tinh gọn, tự co giãn theo kích thước màn hình
  Widget _buildQueueFlowDiagram() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;

        if (isWide) {
          // Giao diện dạng thanh hàng ngang (Pipeline) hiện đại, tinh gọn trên màn hình rộng
          return Row(
            children: [
              Expanded(
                child: _buildCompactNode(
                  stepNum: '1',
                  title: 'Mã Đồng Bộ',
                  subtitle: 'Call Stack chạy tuần tự',
                  example: 'print(), lệnh gán, tính toán',
                  color: Colors.blueAccent,
                  icon: Icons.flash_on,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.grey),
              ),
              Expanded(
                child: _buildCompactNode(
                  stepNum: '2',
                  title: 'Microtask Queue',
                  subtitle: 'Ưu tiên giải quyết trước',
                  example: 'scheduleMicrotask()',
                  color: Colors.pinkAccent,
                  icon: Icons.priority_high,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.grey),
              ),
              Expanded(
                child: _buildCompactNode(
                  stepNum: '3',
                  title: 'Event Queue',
                  subtitle: 'Chạy sau khi hết microtask',
                  example: 'Future(), Timer, Stream',
                  color: Colors.amberAccent,
                  icon: Icons.hourglass_top,
                ),
              ),
            ],
          );
        }

        // Giao diện danh sách gọn nhẹ cho màn hình hẹp
        return Column(
          children: [
            _buildCompactNode(
              stepNum: '1',
              title: 'Mã Đồng Bộ (Call Stack)',
              subtitle: 'Chạy tuần tự ngay lập tức',
              example: 'print(), lệnh gán',
              color: Colors.blueAccent,
              icon: Icons.flash_on,
            ),
            const SizedBox(height: 6),
            const Icon(Icons.arrow_downward_rounded, size: 16, color: Colors.grey),
            const SizedBox(height: 6),
            _buildCompactNode(
              stepNum: '2',
              title: 'Microtask Queue (Ưu Tiên Cao)',
              subtitle: 'Ưu tiên giải quyết trước mọi Future',
              example: 'scheduleMicrotask(), Future.microtask()',
              color: Colors.pinkAccent,
              icon: Icons.priority_high,
            ),
            const SizedBox(height: 6),
            const Icon(Icons.arrow_downward_rounded, size: 16, color: Colors.grey),
            const SizedBox(height: 6),
            _buildCompactNode(
              stepNum: '3',
              title: 'Event Queue (Sự Kiện Sau Cùng)',
              subtitle: 'Chỉ chạy sau khi Microtask Queue trống',
              example: 'Future(), Timer, Stream',
              color: Colors.amberAccent,
              icon: Icons.hourglass_top,
            ),
          ],
        );
      },
    );
  }

  /// Khối thông tin nhỏ gọn cho từng bước trong Event Loop
  Widget _buildCompactNode({
    required String stepNum,
    required String title,
    required String subtitle,
    required String example,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNum,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 3),
          Text(
            example,
            style: TextStyle(fontSize: 10, color: Colors.grey[400], fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
