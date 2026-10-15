import 'dart:async';
import 'package:flutter/material.dart';
import '../core/transformers/stream_transformers.dart';
import '../models/crypto_asset.dart';
import '../models/market_tick.dart';
import '../services/crypto_price_stream_service.dart';
import '../widgets/price_ticker_card.dart';
import '../widgets/stream_lifecycle_badge.dart';
import 'crypto_detail_screen.dart';

/// Market screen displaying real-time cryptocurrency tickers using StreamBuilder
/// and Debounced reactive search input filtering.
class CryptoMarketScreen extends StatefulWidget {
  const CryptoMarketScreen({super.key});

  @override
  State<CryptoMarketScreen> createState() => _CryptoMarketScreenState();
}

class _CryptoMarketScreenState extends State<CryptoMarketScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // StreamController for debounced search queries
  final StreamController<String> _searchQueryController = StreamController<String>();
  StreamSubscription<String>? _searchSubscription;

  String _currentQuery = '';
  String _selectedCategory = 'Tất cả';
  bool _isSearchingDebounced = false;

  final List<String> _categories = ['Tất cả', 'Layer 1', 'DeFi', 'Payment', 'Oracle'];

  @override
  void initState() {
    super.initState();

    // Set up debounced search stream: waits 400ms after user pauses typing
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
          IconButton(
            tooltip: 'Tùy chỉnh tần số Stream',
            icon: const Icon(Icons.tune),
            onPressed: () => _showStreamConfigDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<MarketTick>(
        // Listen to the central broadcast stream
        stream: service.marketStream,
        builder: (context, snapshot) {
          final latestTick = snapshot.data;
          final allAssets = service.currentAssets;
          final filteredAssets = _filterAssets(allAssets);

          return Column(
            children: [
              // Header Status Panel with Stream info
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
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: service.isRunning
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                boxShadow: [
                                  BoxShadow(
                                    color: (service.isRunning
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444))
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              service.isRunning
                                  ? 'Stream: ${service.tickIntervalMs}ms / tick'
                                  : 'Stream: Đang tạm dừng',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
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

              // Search Bar with Debounce Indicator
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

              // Category Filter Chips
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

              // Crypto Assets List
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
