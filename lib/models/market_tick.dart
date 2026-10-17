/// Mô hình một biến động giá đơn lẻ trên thị trường theo thời gian thực
class MarketTick {
  final String symbol;
  final double price;
  final double change;
  final double percentChange;
  final DateTime timestamp;
  final double volume;

  const MarketTick({
    required this.symbol,
    required this.price,
    required this.change,
    required this.percentChange,
    required this.timestamp,
    required this.volume,
  });

  bool get isUp => change >= 0;

  factory MarketTick.fromJson(Map<String, dynamic> json) {
    return MarketTick(
      symbol: json['symbol'] as String,
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      percentChange: (json['percentChange'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      volume: (json['volume'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'price': price,
    'change': change,
    'percentChange': percentChange,
    'timestamp': timestamp.toIso8601String(),
    'volume': volume,
  };
}
