import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/crypto_asset.dart';
import '../models/market_tick.dart';

/// Chế độ nguồn dữ liệu: Mô phỏng Brownian Motion hoặc Kết nối trực tiếp Binance WebSocket
enum DataSourceMode { simulation, binanceLive }

/// Dịch vụ Reactive Trung tâm: Quản lý luồng phát dữ liệu giá thời gian thực qua Dart Broadcast Streams.
/// Hiện thực cơ chế quản lý vòng đời Stream an toàn, theo dõi số lượng người nghe và phát đa hướng (multi-cast).
class CryptoPriceStreamService {
  // Áp dụng mẫu thiết kế Singleton để phân phối luồng dữ liệu tập trung duy nhất trong toàn ứng dụng
  static final CryptoPriceStreamService _instance = CryptoPriceStreamService._internal();
  factory CryptoPriceStreamService() => _instance;
  static CryptoPriceStreamService get instance => _instance;

  CryptoPriceStreamService._internal() {
    _initAssets();
    _initBroadcastController();
    startSimulation();
  }

  final Random _random = Random();
  Timer? _tickTimer;
  
  // Theo dõi số lượng người đăng ký (subscriber) đang kết nối tới broadcast stream
  int _activeListenersCount = 0;
  int get activeListenersCount => _activeListenersCount;

  // StreamController được cấu hình đặc biệt dưới dạng BROADCAST stream
  // Cho phép nhiều Widget (Danh sách thị trường, Header, Chi tiết Coin) cùng lắng nghe đồng thời.
  late StreamController<MarketTick> _priceStreamController;

  /// Luồng phát các bước giá thời gian thực (MarketTick) sẵn sàng cho tất cả các màn hình lắng nghe.
  Stream<MarketTick> get marketStream => _priceStreamController.stream;

  /// StreamController phát sự thay đổi về số lượng người nghe để phục vụ việc giám sát trên giao diện
  final StreamController<int> _listenerTrackerController = StreamController<int>.broadcast();
  Stream<int> get listenerCountStream => _listenerTrackerController.stream;

  // Mode Controller: Phát thông báo khi chuyển đổi giữa Mô phỏng và Binance Live
  DataSourceMode _currentMode = DataSourceMode.simulation;
  DataSourceMode get currentMode => _currentMode;
  bool get isBinanceLive => _currentMode == DataSourceMode.binanceLive;

  final StreamController<DataSourceMode> _modeController = StreamController<DataSourceMode>.broadcast();
  Stream<DataSourceMode> get modeStream => _modeController.stream;

  WebSocketChannel? _binanceChannel;
  StreamSubscription? _binanceSubscription;
  String _binanceStatus = 'Mô phỏng nội bộ';
  String get binanceStatus => _binanceStatus;

  // Kho lưu trữ danh sách tài sản tiền mã hóa nội bộ
  final Map<String, CryptoAsset> _assetsMap = {};
  List<CryptoAsset> get currentAssets => _assetsMap.values.toList();

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  int _tickIntervalMs = 1200;
  int get tickIntervalMs => _tickIntervalMs;

  /// Khởi tạo StreamController dưới dạng Broadcast để cho phép nhiều Widget cùng lắng nghe,
  /// đồng thời theo dõi onListen và onCancel để quản lý vòng đời người nghe.
  void _initBroadcastController() {
    _priceStreamController = StreamController<MarketTick>.broadcast(
      onListen: () {
        _activeListenersCount++;
        _listenerTrackerController.add(_activeListenersCount);
      },
      onCancel: () {
        if (_activeListenersCount > 0) {
          _activeListenersCount--;
        }
        _listenerTrackerController.add(_activeListenersCount);
      },
      sync: false,
    );
  }

  void _initAssets() {
    final initialData = [
      CryptoAsset(
        id: 'bitcoin',
        symbol: 'BTC',
        name: 'Bitcoin',
        category: 'Layer 1',
        currentPrice: 68420.50,
        change24h: 3.45,
        high24h: 69200.0,
        low24h: 66800.0,
        volume24h: 28540000000,
        sparkline: [67100, 67400, 67200, 67900, 68100, 67800, 68420.50],
        lastUpdated: DateTime.now(),
      ),
      CryptoAsset(
        id: 'ethereum',
        symbol: 'ETH',
        name: 'Ethereum',
        category: 'Layer 1',
        currentPrice: 3540.20,
        change24h: -1.25,
        high24h: 3620.0,
        low24h: 3480.0,
        volume24h: 15420000000,
        sparkline: [3590, 3610, 3570, 3530, 3510, 3550, 3540.20],
        lastUpdated: DateTime.now(),
      ),
      CryptoAsset(
        id: 'solana',
        symbol: 'SOL',
        name: 'Solana',
        category: 'Layer 1',
        currentPrice: 178.60,
        change24h: 6.82,
        high24h: 182.0,
        low24h: 165.5,
        volume24h: 6200000000,
        sparkline: [166, 168, 172, 170, 175, 177, 178.60],
        lastUpdated: DateTime.now(),
      ),
      CryptoAsset(
        id: 'binancecoin',
        symbol: 'BNB',
        name: 'BNB',
        category: 'DeFi',
        currentPrice: 592.40,
        change24h: 0.95,
        high24h: 601.0,
        low24h: 585.0,
        volume24h: 1800000000,
        sparkline: [586, 588, 590, 589, 591, 590, 592.40],
        lastUpdated: DateTime.now(),
      ),
      CryptoAsset(
        id: 'ripple',
        symbol: 'XRP',
        name: 'Ripple',
        category: 'Payment',
        currentPrice: 0.584,
        change24h: -2.14,
        high24h: 0.602,
        low24h: 0.572,
        volume24h: 1200000000,
        sparkline: [0.595, 0.598, 0.591, 0.588, 0.582, 0.586, 0.584],
        lastUpdated: DateTime.now(),
      ),
      CryptoAsset(
        id: 'cardano',
        symbol: 'ADA',
        name: 'Cardano',
        category: 'Layer 1',
        currentPrice: 0.462,
        change24h: 4.12,
        high24h: 0.475,
        low24h: 0.440,
        volume24h: 650000000,
        sparkline: [0.442, 0.448, 0.455, 0.450, 0.458, 0.460, 0.462],
        lastUpdated: DateTime.now(),
      ),
      CryptoAsset(
        id: 'avalanche-2',
        symbol: 'AVAX',
        name: 'Avalanche',
        category: 'Layer 1',
        currentPrice: 28.75,
        change24h: -0.65,
        high24h: 29.80,
        low24h: 27.90,
        volume24h: 450000000,
        sparkline: [29.1, 29.4, 28.9, 28.5, 28.8, 28.6, 28.75],
        lastUpdated: DateTime.now(),
      ),
      CryptoAsset(
        id: 'chainlink',
        symbol: 'LINK',
        name: 'Chainlink',
        category: 'Oracle',
        currentPrice: 12.35,
        change24h: 5.20,
        high24h: 12.80,
        low24h: 11.60,
        volume24h: 380000000,
        sparkline: [11.7, 11.9, 12.1, 12.0, 12.2, 12.3, 12.35],
        lastUpdated: DateTime.now(),
      ),
    ];

    for (final a in initialData) {
      _assetsMap[a.symbol] = a;
    }
  }

  /// Khởi động vòng lặp bất đồng bộ mô phỏng các bước nhảy giá (Ticker Event Loop).
  void startSimulation() {
    if (_isRunning) return;
    _isRunning = true;

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(Duration(milliseconds: _tickIntervalMs), (timer) {
      _generateRandomTick();
    });
  }

  /// Tạm dừng bộ sinh luồng dữ liệu mô phỏng.
  void pauseSimulation() {
    _isRunning = false;
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// Cập nhật tần số phát Stream động (ví dụ: từ 500ms tốc độ cao sang 3000ms tiết kiệm pin).
  void setTickInterval(int intervalMs) {
    _tickIntervalMs = intervalMs;
    if (_isRunning) {
      pauseSimulation();
      startSimulation();
    }
  }

  /// Sinh một bước nhảy giá ngẫu nhiên thực tế sử dụng mô hình toán học Chuyển động Brown (Brownian Motion).
  void _generateRandomTick() {
    if (_priceStreamController.isClosed) return;

    final symbols = _assetsMap.keys.toList();
    final chosenSymbol = symbols[_random.nextInt(symbols.length)];
    final asset = _assetsMap[chosenSymbol]!;

    // Biên độ biến động ngẫu nhiên (-1.2% đến +1.2%)
    final percentDelta = (_random.nextDouble() * 2.4 - 1.15) / 100.0;
    final priceDelta = asset.currentPrice * percentDelta;
    final newPrice = max(0.0001, asset.currentPrice + priceDelta);

    asset.applyTick(newPrice);

    final tick = MarketTick(
      symbol: chosenSymbol,
      price: newPrice,
      change: priceDelta,
      percentChange: percentDelta * 100,
      timestamp: DateTime.now(),
      volume: (1000 + _random.nextDouble() * 50000),
    );

    // Bắn bước giá mới vào Stream cho tất cả các Listener đang lắng nghe
    _priceStreamController.add(tick);
  }

  /// Lọc luồng Stream cho riêng một mã coin cụ thể bằng toán tử where
  Stream<MarketTick> getStreamForSymbol(String symbol) {
    return marketStream.where((tick) => tick.symbol.toUpperCase() == symbol.toUpperCase());
  }

  /// Lấy thông tin một đồng tiền mã hóa theo mã ký hiệu (Symbol).
  CryptoAsset? getAsset(String symbol) {
    return _assetsMap[symbol.toUpperCase()];
  }

  /// Mở kết nối WebSocket thời gian thực tới sàn Binance (kênh !miniTicker@arr)
  Future<void> connectToBinance() async {
    pauseSimulation();
    _currentMode = DataSourceMode.binanceLive;
    _modeController.add(_currentMode);
    _binanceStatus = 'Đang kết nối...';

    _disconnectBinance();

    try {
      final wsUrl = Uri.parse('wss://stream.binance.com:9443/ws/!miniTicker@arr');
      _binanceChannel = WebSocketChannel.connect(wsUrl);
      _binanceStatus = 'Đang trực tiếp (wss://stream.binance.com)';

      _binanceSubscription = _binanceChannel!.stream.listen(
        (dynamic rawData) {
          _handleBinanceData(rawData);
        },
        onError: (error) {
          debugPrint('[BINANCE_WS] Lỗi: $error');
          _binanceStatus = 'Lỗi kết nối - Chuyển sang mô phỏng';
          switchToSimulation();
        },
        onDone: () {
          debugPrint('[BINANCE_WS] Đã ngắt kết nối');
          if (_currentMode == DataSourceMode.binanceLive) {
            _binanceStatus = 'Đã ngắt kết nối';
          }
        },
      );
    } catch (e) {
      debugPrint('[BINANCE_WS] Ngoại lệ kết nối: $e');
      switchToSimulation();
    }
  }

  /// Bóc tách dữ liệu JSON từ Binance và đẩy vào StreamController
  void _handleBinanceData(dynamic rawData) {
    if (_priceStreamController.isClosed) return;
    try {
      final decoded = jsonDecode(rawData.toString());
      if (decoded is List) {
        for (final item in decoded) {
          final symbolRaw = item['s'] as String?;
          if (symbolRaw == null || !symbolRaw.endsWith('USDT')) continue;

          // Cắt bỏ đuôi 'USDT' để lấy mã ký hiệu gốc: 'BTCUSDT' -> 'BTC'
          final baseSymbol = symbolRaw.substring(0, symbolRaw.length - 4);
          final asset = _assetsMap[baseSymbol];

          if (asset != null) {
            final closePrice = double.tryParse(item['c']?.toString() ?? '');
            final openPrice = double.tryParse(item['o']?.toString() ?? '');
            final highPrice = double.tryParse(item['h']?.toString() ?? '');
            final lowPrice = double.tryParse(item['l']?.toString() ?? '');
            final quoteVolume = double.tryParse(item['q']?.toString() ?? '');

            if (closePrice != null && closePrice > 0) {
              final percentChange = (openPrice != null && openPrice > 0)
                  ? ((closePrice - openPrice) / openPrice) * 100
                  : asset.change24h;
              final priceDelta = closePrice - asset.currentPrice;

              asset.applyBinanceTick(
                newPrice: closePrice,
                newChange24h: percentChange,
                newHigh24h: highPrice ?? asset.high24h,
                newLow24h: lowPrice ?? asset.low24h,
                newVolume24h: quoteVolume ?? asset.volume24h,
              );

              final tick = MarketTick(
                symbol: baseSymbol,
                price: closePrice,
                change: priceDelta,
                percentChange: percentChange,
                timestamp: DateTime.now(),
                volume: quoteVolume ?? asset.volume24h,
              );

              _priceStreamController.add(tick);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[BINANCE_DATA_PARSE] Ngoại lệ: $e');
    }
  }

  /// Chuyển về chế độ Mô Phỏng nội bộ
  void switchToSimulation() {
    _disconnectBinance();
    _currentMode = DataSourceMode.simulation;
    _binanceStatus = 'Mô phỏng nội bộ';
    _modeController.add(_currentMode);
    startSimulation();
  }

  void _disconnectBinance() {
    _binanceSubscription?.cancel();
    _binanceSubscription = null;
    _binanceChannel?.sink.close();
    _binanceChannel = null;
  }

  /// Chuyển đổi qua lại giữa Mô Phỏng và Binance Live WebSocket
  Future<void> toggleDataSource() async {
    if (_currentMode == DataSourceMode.simulation) {
      await connectToBinance();
    } else {
      switchToSimulation();
    }
  }

  /// Hàm hủy an toàn: đóng toàn bộ StreamController và giải phóng tài nguyên
  Future<void> dispose() async {
    pauseSimulation();
    _disconnectBinance();
    if (!_priceStreamController.isClosed) {
      await _priceStreamController.close();
    }
    if (!_listenerTrackerController.isClosed) {
      await _listenerTrackerController.close();
    }
    if (!_modeController.isClosed) {
      await _modeController.close();
    }
  }
}
