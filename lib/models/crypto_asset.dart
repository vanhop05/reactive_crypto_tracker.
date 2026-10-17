/// Mô hình dữ liệu crypto
class CryptoAsset {
  final String id;
  final String symbol;
  final String name;
  final String category;
  double currentPrice;
  double change24h;
  double high24h;
  double low24h;
  double volume24h;
  List<double> sparkline;
  DateTime lastUpdated;

  CryptoAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.category,
    required this.currentPrice,
    required this.change24h,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    required this.sparkline,
    required this.lastUpdated,
  });

  bool get isPositive => change24h >= 0;
  //Cập nhật giá mới
  void applyTick(double newPrice) {
    if (newPrice > high24h) high24h = newPrice;
    if (newPrice < low24h) low24h = newPrice;
    
    // Giũ lại 25 giá gần gần nhất làm sparkline
    sparkline.add(newPrice);
    if (sparkline.length > 25) {
      sparkline.removeAt(0);
    }

    final diff = newPrice - currentPrice;
    change24h = currentPrice != 0 ? ((diff / currentPrice) * 100) : 0;
    currentPrice = newPrice;
    lastUpdated = DateTime.now();
  }
  // Tao bản sao 
  CryptoAsset copyWith({
    String? id,
    String? symbol,
    String? name,
    String? category,
    double? currentPrice,
    double? change24h,
    double? high24h,
    double? low24h,
    double? volume24h,
    List<double>? sparkline,
    DateTime? lastUpdated,
  }) {
    return CryptoAsset(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      category: category ?? this.category,
      currentPrice: currentPrice ?? this.currentPrice,
      change24h: change24h ?? this.change24h,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      volume24h: volume24h ?? this.volume24h,
      sparkline: sparkline ?? List.from(this.sparkline),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
