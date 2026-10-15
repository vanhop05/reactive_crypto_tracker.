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

/// Screen displaying granular real-time information for a specific coin.
/// Serves as the primary practical demonstration of:
/// 1. Subscribing to a Broadcast Stream
/// 2. Applying Stream Transformers (Throttle/Debounce)
/// 3. Safely cancelling subscriptions on dispose() to avoid Memory Leaks.
class CryptoDetailScreen extends StatefulWidget {
  final CryptoAsset initialAsset;

  const CryptoDetailScreen({super.key, required this.initialAsset});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  late CryptoAsset _asset;
  
  // Stream subscriptions that MUST be cleanly cancelled in dispose()
  StreamSubscription<MarketTick>? _tickSubscription;
  StreamSubscription<int>? _activeListenerSubscription;
  
  late OrderBookStreamService _orderBookService;
  StreamSubscription<List<OrderBookEntry>>? _orderBookSub;
  List<OrderBookEntry> _orderBookEntries = [];

  // Tracking metrics for the Rubric Demonstration
  int _receivedTicksCount = 0;
  int _activeSubscribersInApp = 0;
  bool _simulateMemoryLeak = false; // Demonstration toggle
  DateTime? _lastTickTime;

  @override
  void initState() {
    super.initState();
    _asset = widget.initialAsset;

    _orderBookService = OrderBookStreamService(
      symbol: _asset.symbol,
      currentPrice: _asset.currentPrice,
    );

    // 1. Subscribe to order book depth stream
    _orderBookSub = _orderBookService.stream.listen((entries) {
      if (mounted) {
        setState(() {
          _orderBookEntries = entries;
        });
      }
    });

    // 2. Subscribe to the global listener tracker to observe stream lifecycle
    _activeSubscribersInApp = CryptoPriceStreamService.instance.activeListenersCount;
    _activeListenerSubscription =
        CryptoPriceStreamService.instance.listenerCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _activeSubscribersInApp = count;
        });
      }
    });

    // 3. Connect to the symbol-specific Broadcast Stream with throttling
    _connectPriceStream();
  }

  void _connectPriceStream() {
    _tickSubscription?.cancel();

    // Demonstrate listening to symbol-filtered broadcast stream
    _tickSubscription = CryptoPriceStreamService.instance
        .getStreamForSymbol(_asset.symbol)
        .throttle(const Duration(milliseconds: 300)) // Throttle to prevent excessive UI rebuilds
        .listen(
      (tick) {
        if (!mounted) return;
        setState(() {
          _receivedTicksCount++;
          _lastTickTime = tick.timestamp;
          _asset.applyTick(tick.price);
        });
      },
      onError: (Object error) {
        debugPrint('Stream error encountered: $error');
      },
      onDone: () {
        debugPrint('Price stream closed for ${_asset.symbol}');
      },
      cancelOnError: false,
    );
  }

  /// CRITICAL: Flutter Lifecycle dispose method.
  /// Safely cancels stream subscriptions when user navigates away (pops the screen).
  @override
  void dispose() {
    if (_simulateMemoryLeak) {
      // Intentionally leak for demonstration if toggle was activated
      debugPrint('[WARNING] Giả lập rò rỉ: StreamSubscription KHÔNG được hủy!');
    } else {
      // Proper safe stream disposal
      _tickSubscription?.cancel();
      _tickSubscription = null;
      _activeListenerSubscription?.cancel();
      _activeListenerSubscription = null;
      _orderBookSub?.cancel();
      _orderBookSub = null;
      _orderBookService.dispose();
      debugPrint('[SAFE DISPOSE] Đã hủy toàn bộ StreamSubscription thành công!');
    }

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
            tooltip: 'Làm mới stream',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _connectPriceStream();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã tái thiết lập kết nối Stream!'),
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
            // Stream Safety Banner & Monitor
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _simulateMemoryLeak
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _simulateMemoryLeak ? Icons.warning_amber : Icons.security,
                            color: _simulateMemoryLeak
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Giám Sát Vòng Đời Luồng (Stream Lifecycle)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      StreamLifecycleBadge(
                        activeListeners: _activeSubscribersInApp,
                        label: 'Total Subs',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _simulateMemoryLeak
                        ? 'CẢNH BÁO: Chế độ giả lập rò rỉ bộ nhớ đang BẬT. Khi bạn Back ra màn hình trước, StreamSubscription sẽ KHÔNG được hủy để kiểm tra cảnh báo!'
                        : 'AN TOÀN: Cơ chế dispose() sẽ tự động gọi _tickSubscription.cancel() khi thoát màn hình để ngăn chặn Memory Leak.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _simulateMemoryLeak ? const Color(0xFFFCA5A5) : Colors.grey[300],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      Switch(
                        value: _simulateMemoryLeak,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (val) {
                          setState(() {
                            _simulateMemoryLeak = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price Header Card
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
                  // Real-time Chart
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

            // 24h Statistics Grid
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

            // Order Book Widget
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
