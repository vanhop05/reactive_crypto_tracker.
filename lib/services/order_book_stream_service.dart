import 'dart:async';
import 'dart:math';
import '../models/order_book_entry.dart';

/// Service generating and streaming live order book depth (Bids & Asks)
class OrderBookStreamService {
  final String symbol;
  final double currentPrice;
  late StreamController<List<OrderBookEntry>> _orderBookController;
  Timer? _depthTimer;
  final Random _random = Random();

  OrderBookStreamService({
    required this.symbol,
    required this.currentPrice,
  }) {
    _orderBookController = StreamController<List<OrderBookEntry>>.broadcast(
      onListen: _startStreaming,
      onCancel: _stopStreaming,
    );
  }

  Stream<List<OrderBookEntry>> get stream => _orderBookController.stream;

  void _startStreaming() {
    _depthTimer?.cancel();
    _depthTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _emitNewDepth();
    });
    _emitNewDepth();
  }

  void _stopStreaming() {
    _depthTimer?.cancel();
    _depthTimer = null;
  }

  void _emitNewDepth() {
    if (_orderBookController.isClosed) return;

    final List<OrderBookEntry> entries = [];
    double runningBidTotal = 0.0;
    double runningAskTotal = 0.0;

    // Generate 6 Bids (Buy orders, price < currentPrice)
    for (int i = 1; i <= 6; i++) {
      final bidPrice = currentPrice * (1 - (i * 0.0015) - (_random.nextDouble() * 0.0005));
      final amount = 0.1 + _random.nextDouble() * 3.5;
      runningBidTotal += amount;
      entries.add(OrderBookEntry(
        price: bidPrice,
        amount: amount,
        total: runningBidTotal,
        isBid: true,
      ));
    }

    // Generate 6 Asks (Sell orders, price > currentPrice)
    for (int i = 1; i <= 6; i++) {
      final askPrice = currentPrice * (1 + (i * 0.0015) + (_random.nextDouble() * 0.0005));
      final amount = 0.1 + _random.nextDouble() * 3.5;
      runningAskTotal += amount;
      entries.add(OrderBookEntry(
        price: askPrice,
        amount: amount,
        total: runningAskTotal,
        isBid: false,
      ));
    }

    _orderBookController.add(entries);
  }

  /// Safe dispose
  Future<void> dispose() async {
    _stopStreaming();
    if (!_orderBookController.isClosed) {
      await _orderBookController.close();
    }
  }
}
