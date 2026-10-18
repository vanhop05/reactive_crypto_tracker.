import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/transformers/stream_transformers.dart';
import '../models/crypto_asset.dart';
import '../models/market_tick.dart';
import '../models/order_book_entry.dart';
import '../services/crypto_price_stream_service.dart';
import '../services/order_book_stream_service.dart';
import '../widgets/mini_price_chart.dart';
import '../widgets/order_book_widget.dart';
import '../widgets/stream_lifecycle_badge.dart';

/// Màn hình Chi Tiết Coin: Minh chứng thực tế cho 3 yêu cầu cốt lõi:
/// 1. [YÊU CẦU 4]: Lắng nghe luồng Broadcast Stream đa hướng (cùng lúc với Trang chủ).
/// 2. [YÊU CẦU 5]: Áp dụng toán tử Throttle (300ms) để tiết lưu sự kiện, chống quá tải UI.
/// 3. [QUẢN LÝ VÒNG ĐỜI]: Hủy đăng ký an toàn trong dispose() để chống thất thoát bộ nhớ (Memory Leak).
class CryptoDetailScreen extends StatefulWidget {
  final CryptoAsset initialAsset;

  const CryptoDetailScreen({super.key, required this.initialAsset});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  late CryptoAsset _asset;

  // Luồng đăng ký giá (Bắt buộc phải hủy trong dispose)
  StreamSubscription<MarketTick>? _tickSubscription;
  StreamSubscription<int>? _activeListenerSubscription;

  // Sổ lệnh mua/bán thời gian thực
  late OrderBookStreamService _orderBookService;
  StreamSubscription<List<OrderBookEntry>>? _orderBookSub;
  List<OrderBookEntry> _orderBookEntries = [];

  int _receivedTicksCount = 0;
  int _activeSubscribersInApp = 0;
  DateTime? _lastTickTime;

  @override
  void initState() {
    super.initState();
    _asset = widget.initialAsset;

    // Khởi tạo dịch vụ sổ lệnh cho đồng coin này
    _orderBookService = OrderBookStreamService(
      symbol: _asset.symbol,
      currentPrice: _asset.currentPrice,
    );

    // Lắng nghe luồng sổ lệnh
    _orderBookSub = _orderBookService.stream.listen((entries) {
      if (mounted) {
        setState(() {
          _orderBookEntries = entries;
        });
      }
    });

    // Lắng nghe số lượng subscriber đang kết nối tới Broadcast Stream
    _activeSubscribersInApp = CryptoPriceStreamService.instance.activeListenersCount;
    _activeListenerSubscription =
        CryptoPriceStreamService.instance.listenerCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _activeSubscribersInApp = count;
        });
      }
    });

    // Lắng nghe luồng giá có áp dụng toán tử Throttle
    _connectPriceStream();
  }

  /// [YÊU CẦU 4 & 5]: Lắng nghe Broadcast Stream và áp dụng toán tử Throttle 300ms
  void _connectPriceStream() {
    _tickSubscription?.cancel();

    _tickSubscription = CryptoPriceStreamService.instance
        .getStreamForSymbol(_asset.symbol)
        .throttle(const Duration(milliseconds: 300)) // Tiết lưu: tối đa 1 lần render mỗi 300ms
        .listen(
      (tick) {
        if (!mounted) return;
        setState(() {
          _receivedTicksCount++;
          _lastTickTime = tick.timestamp;
          _asset.applyTick(tick.price);
        });
      },
      onError: (error) {
        debugPrint('[STREAM_ERROR] Lỗi khi nhận dữ liệu: $error');
      },
    );
  }

  /// [QUAN TRỌNG NHẤT]: Hủy toàn bộ StreamSubscription khi người dùng bấm Back
  /// Giúp giải phóng tài nguyên và chống tràn bộ nhớ (Memory Leak)
  @override
  void dispose() {
    _tickSubscription?.cancel();
    _tickSubscription = null;
    _activeListenerSubscription?.cancel();
    _activeListenerSubscription = null;
    _orderBookSub?.cancel();
    _orderBookSub = null;
    _orderBookService.dispose();

    debugPrint('[DISPOSE_AN_TOAN] Đã giải phóng toàn bộ Stream cho ${_asset.symbol}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: _asset.currentPrice < 1.0 ? 4 : 2,
    );
    final isPositive = _asset.isPositive;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_asset.name} (${_asset.symbol})'),
        actions: [
          IconButton(
            tooltip: 'Kết nối lại luồng',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _connectPriceStream();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã làm mới kết nối Stream!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ giám sát vòng đời Stream & Đếm số lượng Listener
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.5),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Giám Sát Vòng Đời Luồng (Stream Lifecycle)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      StreamLifecycleBadge(
                        activeListeners: _activeSubscribersInApp,
                        label: 'Active Subs',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An toàn bộ nhớ: StreamSubscription được quản lý chặt chẽ và tự động hủy hoàn toàn trong dispose() khi bạn thoát màn hình này.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[300], height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số tick đã nhận: $_receivedTicksCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF06B6D4),
                          fontFamily: 'monospace',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Throttle 300ms Kích Hoạt',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Thẻ thông tin giá lớn & Biểu đồ Sparkline
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormatter.format(_asset.currentPrice),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 16,
                                color: isPositive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${isPositive ? '+' : ''}${_asset.change24h.toStringAsFixed(2)}% (24h)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isPositive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Cập nhật: ${_lastTickTime != null ? DateFormat('HH:mm:ss').format(_lastTickTime!) : 'Chờ tick...'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Biểu đồ giá thời gian thực
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: MiniPriceChart(
                      dataPoints: _asset.sparkline,
                      isPositive: isPositive,
                      height: 140,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lưới 4 chỉ số thống kê 24h
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Cao Nhất 24h',
                      value: currencyFormatter.format(_asset.high24h),
                      icon: Icons.trending_up,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Thấp Nhất 24h',
                      value: currencyFormatter.format(_asset.low24h),
                      icon: Icons.trending_down,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Khối Lượng 24h',
                      value: NumberFormat.compactCurrency(symbol: '\$').format(_asset.volume24h),
                      icon: Icons.bar_chart,
                      color: const Color(0xFF06B6D4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Toán Tử Stream',
                      value: 'Throttle (300ms)',
                      icon: Icons.filter_alt,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sổ lệnh mua bán (Order Book)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OrderBookWidget(entries: _orderBookEntries),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
