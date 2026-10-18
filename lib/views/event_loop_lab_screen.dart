import 'package:flutter/material.dart';
import '../models/event_loop_step.dart';
import '../services/event_loop_simulator_service.dart';

/// Màn hình mô phỏng trực quan cơ chế Dart Event Loop:
/// Chứng minh thứ tự ưu tiên: Mã Đồng Bộ -> Microtask Queue -> Event Queue (Future / Timer).
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
        title: const Text('Mô Phỏng Dart Event Loop'),
        actions: [
          IconButton(
            tooltip: 'Xóa kết quả',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _simulatorService.clear();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Khung điều khiển duy nhất: Tinh gọn và trực quan
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
                      Icon(Icons.hub_outlined, color: Color(0xFF10B981), size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thực Nghiệm Thứ Tự Ưu Tiên Event Loop',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Quy tắc vàng: Mã Đồng Bộ chạy ngay ➔ Hút sạch Microtask Queue ➔ Bốc Event Queue (Future / Timer).',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[300], height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 22),
                      label: const Text(
                        'Chạy Mô Phỏng Event Loop',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () {
                        _simulatorService.runExperiment();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Khu vực hiển thị nhật ký các bước thực thi
            const Text(
              'Trình Tự Thực Thi Của Event Loop:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder<List<EventLoopStep>>(
              stream: _simulatorService.stepsStream,
              initialData: const [],
              builder: (context, snapshot) {
                final steps = snapshot.data ?? [];

                // Khi chưa nhấn nút chạy
                if (steps.isEmpty) {
                  return Container(
                    height: 180,
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
                          Icon(Icons.terminal, color: Colors.grey[500], size: 40),
                          const SizedBox(height: 10),
                          Text(
                            'Nhấn "Chạy Mô Phỏng Event Loop" ở trên để quan sát',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Khi đã có kết quả thực thi
                return Column(
                  children: [
                    // Thanh tóm tắt kết quả
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kết quả: Đồng Bộ (#1, #7) ➔ Microtask (#3, #4) ➔ Event Queue (#2, #5, #6)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Danh sách từng bước
                    ListView.builder(
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
                                      'Thời gian: +${step.timestampMicroseconds} µs',
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
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
