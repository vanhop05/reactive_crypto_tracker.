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
            // Thẻ hiển thị lý thuyết kiến trúc Event Loop
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
                      Icon(Icons.architecture, color: Color(0xFF06B6D4), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Cơ Chế Dart Event Loop & Hàng Đợi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dart là ngôn ngữ đơn luồng (Single-threaded). Event Loop điều phối việc thực thi mã nguồn thông qua 2 hàng đợi chính theo thứ tự ưu tiên tuyệt đối:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  _buildQueueFlowDiagram(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Card: Run Experiment
            Container(
              padding: const EdgeInsets.all(16),
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
                        const SizedBox(height: 4),
                        Text(
                          'Kiểm chứng Microtask Queue chạy trước Event Queue dù khai báo sau.',
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

            // Live Execution Log Stream
            StreamBuilder<List<EventLoopStep>>(
              stream: _simulatorService.stepsStream,
              initialData: const [],
              builder: (context, snapshot) {
                final steps = snapshot.data ?? [];

                if (steps.isEmpty) {
                  return Container(
                    height: 160,
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

  Widget _buildQueueFlowDiagram() {
    return Column(
      children: [
        _buildDiagramNode('1. Call Stack (Đồng Bộ)', 'Code chạy tuần tự đến khi stack trống', Colors.blueAccent),
        const Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
        _buildDiagramNode('2. Microtask Queue (Ưu Tiên Cao)', 'scheduleMicrotask, Future.microtask', Colors.pinkAccent),
        const Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
        _buildDiagramNode('3. Event Queue (Sự Kiện/Timer/I/O)', 'Future(), Future.delayed(), Stream, User Touch', Colors.amberAccent),
      ],
    );
  }

  Widget _buildDiagramNode(String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
