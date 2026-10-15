import 'dart:async';
import 'dart:math';
import '../models/crypto_asset.dart';
import '../models/market_tick.dart';

/// Central Reactive Service managing real-time price feeds via Dart Broadcast Streams.
/// Implements safe stream lifecycle management, listener tracking, and multi-cast broadcasting.
class CryptoPriceStreamService {
  // Singleton pattern for centralized stream distribution
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
  
  // Track active subscribers connected to the broadcast stream
  int _activeListenersCount = 0;
  int get activeListenersCount => _activeListenersCount;

  // StreamController configured specifically as a BROADCAST stream
  // Allowing multiple widgets (Home List, Header Banner, Coin Details) to listen concurrently.
  late StreamController<MarketTick> _priceStreamController;

  /// Stream of real-time ticks available to all components.
  Stream<MarketTick> get marketStream => _priceStreamController.stream;

  /// Stream Controller to broadcast changes in subscriber count for UI monitoring
  final StreamController<int> _listenerTrackerController = StreamController<int>.broadcast();
  Stream<int> get listenerCountStream => _listenerTrackerController.stream;

  // Internal assets repository
  final Map<String, CryptoAsset> _assetsMap = {};
  List<CryptoAsset> get currentAssets => _assetsMap.values.toList();

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  int _tickIntervalMs = 1200;
  int get tickIntervalMs => _tickIntervalMs;

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

  /// Starts the asynchronous ticker event simulation loop.
  void startSimulation() {
    if (_isRunning) return;
    _isRunning = true;

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(Duration(milliseconds: _tickIntervalMs), (timer) {
      _generateRandomTick();
    });
  }

  /// Pauses the live data stream generator.
  void pauseSimulation() {
    _isRunning = false;
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// Updates simulation frequency dynamically (e.g. from 500ms high-speed to 3000ms low-power).
  void setTickInterval(int intervalMs) {
    _tickIntervalMs = intervalMs;
    if (_isRunning) {
      pauseSimulation();
      startSimulation();
    }
  }

  /// Generates a realistic market tick using Brownian motion simulation.
  void _generateRandomTick() {
    if (_priceStreamController.isClosed) return;

    final symbols = _assetsMap.keys.toList();
    final chosenSymbol = symbols[_random.nextInt(symbols.length)];
    final asset = _assetsMap[chosenSymbol]!;

    // Volatility percentage (-1.2% to +1.2%)
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

    // Broadcast tick to all active stream listeners
    _priceStreamController.add(tick);
  }

  /// Obtains a filtered Stream specifically for a single cryptocurrency.
  /// Uses Stream.where operator to transform the broadcast stream.
  Stream<MarketTick> getStreamForSymbol(String symbol) {
    return marketStream.where((tick) => tick.symbol.toUpperCase() == symbol.toUpperCase());
  }

  /// Fetches an asset by its symbol.
  CryptoAsset? getAsset(String symbol) {
    return _assetsMap[symbol.toUpperCase()];
  }

  /// Safe dispose method to close all controllers and release timers.
  Future<void> dispose() async {
    pauseSimulation();
    if (!_priceStreamController.isClosed) {
      await _priceStreamController.close();
    }
    if (!_listenerTrackerController.isClosed) {
      await _listenerTrackerController.close();
    }
  }
}
