import 'dart:async';
import 'package:flutter/material.dart';
import '../core/transformers/stream_transformers.dart';
import '../models/crypto_asset.dart';
import '../models/market_tick.dart';
import '../services/crypto_price_stream_service.dart';
import '../widgets/price_ticker_card.dart';
import '../widgets/stream_lifecycle_badge.dart';
import 'crypto_detail_screen.dart';

/// Màn hình Thị Trường hiển thị giá tiền mã hóa theo thời gian thực
class CryptoMarketScreen extends StatefulWidget {
  const CryptoMarketScreen({super.key});

  @override
  State<CryptoMarketScreen> createState() => _CryptoMarketScreenState();
}

class _CryptoMarketScreenState extends State<CryptoMarketScreen> {
  final TextEditingController _searchController = TextEditingController();

  // StreamController quản lý từ khóa tìm kiếm
  final StreamController<String> _searchQueryController = StreamController<String>();
  StreamSubscription<String>? _searchSubscription;

  String _currentQuery = '';
  String _selectedCategory = 'Tất cả';
  bool _isSearchingDebounced = false;

  final List<String> _categories = ['Tất cả', 'Layer 1', 'DeFi', 'Payment', 'Oracle'];

  @override
  void initState() {
    super.initState();

    // Chờ 400ms sau khi người dùng ngừng gõ phím mới tiến hành lọc danh sách (Debounce)
    _searchSubscription = _searchQueryController.stream
        .debounce(const Duration(milliseconds: 400))
        .listen((query) {
      if (mounted) {
        setState(() {
          _currentQuery = query.trim().toLowerCase();
          _isSearchingDebounced = false;
        });
      }
    });

    _searchController.addListener(() {
      setState(() {
        _isSearchingDebounced = true;
      });
      _searchQueryController.add(_searchController.text);
    });
  }

  // [QUẢN LÝ VÒNG ĐỜI]: Hủy đăng ký và đóng StreamController khi màn hình bị hủy
  @override
  void dispose() {
    _searchSubscription?.cancel();
    _searchQueryController.close();
    _searchController.dispose();
    super.dispose();
  }

  List<CryptoAsset> _filterAssets(List<CryptoAsset> allAssets) {
    return allAssets.where((asset) {
      final matchesQuery = _currentQuery.isEmpty ||
          asset.name.toLowerCase().contains(_currentQuery) ||
          asset.symbol.toLowerCase().contains(_currentQuery);

      final matchesCategory = _selectedCategory == 'Tất cả' ||
          asset.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final service = CryptoPriceStreamService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text(
              'CryptoPulse Reactive',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Nút bấm chuyển đổi nguồn dữ liệu Mô Phỏng / Binance Live
          StreamBuilder<DataSourceMode>(
            stream: service.modeStream,
            initialData: service.currentMode,
            builder: (context, modeSnap) {
              final isBinance = modeSnap.data == DataSourceMode.binanceLive;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: InkWell(
                  onTap: () async {
                    // Gọi hàm bất đồng bộ async / await để mở kết nối WebSocket Binance
                    await service.toggleDataSource();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                service.isBinanceLive ? Icons.sensors : Icons.memory,
                                color: service.isBinanceLive ? const Color(0xFFF3BA2F) : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  service.isBinanceLive
                                      ? '⚡ Đã kết nối WebSocket sàn Binance (wss://stream.binance.com)'
                                      : '🔄 Đã chuyển về chế độ Mô Phỏng nội bộ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1E2329),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isBinance ? const Color(0xFFF3BA2F) : const Color(0xFF10B981)).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isBinance ? const Color(0xFFF3BA2F) : const Color(0xFF10B981),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBinance ? Icons.sensors : Icons.memory,
                          color: isBinance ? const Color(0xFFF3BA2F) : const Color(0xFF10B981),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isBinance ? 'BINANCE LIVE' : 'MÔ PHỎNG',
                          style: TextStyle(
                            color: isBinance ? const Color(0xFFF3BA2F) : const Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Tùy chỉnh tần số Stream',
            icon: const Icon(Icons.tune),
            onPressed: () => _showStreamConfigDialog(context),
          ),
        ],
      ),

      // StreamBuilder tự động cập nhật giao diện khi có dữ liệu giá mới
      body: StreamBuilder<MarketTick>(
        stream: service.marketStream,
        builder: (context, snapshot) {
          final latestTick = snapshot.data;
          final allAssets = service.currentAssets;
          final filteredAssets = _filterAssets(allAssets);

          return Column(
            children: [
              // Thanh trạng thái Stream & Số lượng subscriber
              StreamBuilder<int>(
                stream: service.listenerCountStream,
                initialData: service.activeListenersCount,
                builder: (context, listenerSnap) {
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder<DataSourceMode>(
                          stream: service.modeStream,
                          initialData: service.currentMode,
                          builder: (context, modeSnap) {
                            final isBinance = modeSnap.data == DataSourceMode.binanceLive;
                            final dotColor = isBinance
                                ? const Color(0xFFF3BA2F)
                                : (service.isRunning ? const Color(0xFF10B981) : const Color(0xFFEF4444));
                            return Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: dotColor,
                                    boxShadow: [
                                      BoxShadow(color: dotColor.withOpacity(0.6), blurRadius: 8),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isBinance
                                      ? 'Binance: wss://stream.binance.com'
                                      : (service.isRunning
                                          ? 'Mô phỏng: ${service.tickIntervalMs}ms / tick'
                                          : 'Mô phỏng: Đang tạm dừng'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                    color: isBinance ? const Color(0xFFF3BA2F) : Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        StreamLifecycleBadge(
                          activeListeners: listenerSnap.data ?? 0,
                          label: 'Broadcasting',
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Ô tìm kiếm coin tích hợp toán tử Debounce 400ms
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm coin (Debounce 400ms)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _isSearchingDebounced
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : (_searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQueryController.add('');
                                },
                              )
                            : null),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Bộ lọc danh mục coin
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Danh sách coin
              Expanded(
                child: filteredAssets.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy coin nào phù hợp.',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredAssets.length,
                        itemBuilder: (context, index) {
                          final asset = filteredAssets[index];
                          return PriceTickerCard(
                            asset: asset,
                            latestTick: latestTick,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CryptoDetailScreen(
                                    initialAsset: asset,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Hộp thoại tùy chỉnh tốc độ phát sinh giá mô phỏng
  void _showStreamConfigDialog(BuildContext context) {
    final service = CryptoPriceStreamService.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Điều Khiển Module Reactive Stream',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trạng thái phát dữ liệu:'),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: service.isRunning
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(service.isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(service.isRunning ? 'Tạm Dừng' : 'Phát Tiếp'),
                        onPressed: () {
                          if (service.isRunning) {
                            service.pauseSimulation();
                          } else {
                            service.startSimulation();
                          }
                          setModalState(() {});
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Tốc độ phát sinh tick (ms):'),
                  Slider(
                    value: service.tickIntervalMs.toDouble(),
                    min: 300,
                    max: 3000,
                    divisions: 9,
                    label: '${service.tickIntervalMs} ms',
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      service.setTickInterval(val.toInt());
                      setModalState(() {});
                      setState(() {});
                    },
                  ),
                  Center(
                    child: Text(
                      'Tần số: Mỗi ${service.tickIntervalMs}ms phát 1 sự kiện giá mới',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
