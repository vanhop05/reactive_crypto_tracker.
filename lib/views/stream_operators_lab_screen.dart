import 'dart:async';
import 'package:flutter/material.dart';
import '../core/transformers/stream_transformers.dart';

/// Màn hình phòng thí nghiệm so sánh trực quan các Toán tử Stream:
/// Luồng Gốc (Raw Stream) vs Debounce vs Throttle.
class StreamOperatorsLabScreen extends StatefulWidget {
  const StreamOperatorsLabScreen({super.key});

  @override
  State<StreamOperatorsLabScreen> createState() => _StreamOperatorsLabScreenState();
}

class _StreamOperatorsLabScreenState extends State<StreamOperatorsLabScreen> {
  final TextEditingController _inputController = TextEditingController();

  // StreamController phát nguồn dữ liệu chính
  final StreamController<String> _sourceController = StreamController<String>.broadcast();

  // Các gói đăng ký lắng nghe (Subscriptions)
  StreamSubscription<String>? _rawSub;
  StreamSubscription<String>? _debounceSub;
  StreamSubscription<String>? _throttleSub;

  // Bộ đếm số lượng sự kiện nhận được
  int _rawCount = 0;
  int _debounceCount = 0;
  int _throttleCount = 0;

  String _lastRawValue = '';
  String _lastDebounceValue = '';
  String _lastThrottleValue = '';

  @override
  void initState() {
    super.initState();

    // 1. Luồng Gốc (Raw Stream: lắng nghe trực tiếp, không lọc)
    _rawSub = _sourceController.stream.listen((val) {
      if (mounted) {
        setState(() {
          _rawCount++;
          _lastRawValue = val;
        });
      }
    });

    // 2. Luồng áp dụng Debounce (Chờ 500ms sau khi ngừng nhập)
    _debounceSub = _sourceController.stream
        .debounce(const Duration(milliseconds: 500))
        .listen((val) {
      if (mounted) {
        setState(() {
          _debounceCount++;
          _lastDebounceValue = val;
        });
      }
    });

    // 3. Luồng áp dụng Throttle (Giới hạn tối đa 1 sự kiện mỗi 800ms)
    _throttleSub = _sourceController.stream
        .throttle(const Duration(milliseconds: 800))
        .listen((val) {
      if (mounted) {
        setState(() {
          _throttleCount++;
          _lastThrottleValue = val;
        });
      }
    });

    _inputController.addListener(() {
      _sourceController.add(_inputController.text);
    });
  }

  void _resetCounters() {
    setState(() {
      _rawCount = 0;
      _debounceCount = 0;
      _throttleCount = 0;
      _lastRawValue = '';
      _lastDebounceValue = '';
      _lastThrottleValue = '';
      _inputController.clear();
    });
  }

  @override
  void dispose() {
    _rawSub?.cancel();
    _debounceSub?.cancel();
    _throttleSub?.cancel();
    _sourceController.close();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double debounceSavings = _rawCount > 0
        ? ((_rawCount - _debounceCount) / _rawCount * 100).clamp(0, 100)
        : 0;

    final double throttleSavings = _rawCount > 0
        ? ((_rawCount - _throttleCount) / _rawCount * 100).clamp(0, 100)
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toán Tử Biến Đổi Stream'),
        actions: [
          IconButton(
            tooltip: 'Đặt lại bộ đếm',
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetCounters,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lab description
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
                      Icon(Icons.compare_arrows, color: Color(0xFF8B5CF6), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Thử Nghiệm So Sánh Trực Quan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gõ nhanh một đoạn văn bản vào ô dưới đây để chứng kiến cách Debounce và Throttle giảm tải sự kiện mạng (API Calls) và xử lý UI.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[300], height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live Input Field
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'Gõ văn bản liên tục để kiểm tra luồng:',
                hintText: 'Ví dụ: flutter asynchronous programming stream...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _inputController.clear(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 1. Raw Stream Card
            _buildStreamResultCard(
              title: '1. Luồng Gốc (Raw Stream - Không Lọc)',
              badge: 'TẤT CẢ SỰ KIỆN',
              badgeColor: Colors.blueAccent,
              count: _rawCount,
              currentValue: _lastRawValue,
              description: 'Phát ra sự kiện mỗi khi nhấn 1 phím. Gây spam API và quá tải render UI nếu không được kiểm soát.',
            ),

            const SizedBox(height: 12),

            // 2. Debounce Card
            _buildStreamResultCard(
              title: '2. Debounce (Chờ 500ms Sau Khi Dừng Gõ)',
              badge: 'TIẾT KIỆM ${debounceSavings.toStringAsFixed(1)}%',
              badgeColor: const Color(0xFF10B981),
              count: _debounceCount,
              currentValue: _lastDebounceValue,
              description: 'Chỉ phát dữ liệu khi người dùng NGỪNG gõ phím ít nhất 500ms. Phù hợp nhất cho Search Autocomplete.',
            ),

            const SizedBox(height: 12),

            // 3. Throttle Card
            _buildStreamResultCard(
              title: '3. Throttle (Tối Đa 1 Sự Kiện / 800ms)',
              badge: 'TIẾT KIỆM ${throttleSavings.toStringAsFixed(1)}%',
              badgeColor: const Color(0xFFF59E0B),
              count: _throttleCount,
              currentValue: _lastThrottleValue,
              description: 'Phát ngay sự kiện đầu tiên, sau đó chặn mọi sự kiện phát sinh trong 800ms tiếp theo. Phù hợp cho Button Click / Scroll.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamResultCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required int count,
    required String currentValue,
    required String description,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withOpacity(0.4)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: Colors.grey[400], height: 1.3),
          ),
          const Divider(height: 20, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số lần phát: $count',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Expanded(
                child: Text(
                  'Giá trị: "${currentValue.isEmpty ? '(trống)' : currentValue}"',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF06B6D4),
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
