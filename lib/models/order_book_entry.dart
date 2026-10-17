///Mô hình một mục nhập độ sâu sổ lệnh (Mua/Bán)
class OrderBookEntry {
  final double price;
  final double amount;
  final double total;
  final bool isBid; // buy = true (bid), sell = false (ask)

  const OrderBookEntry({
    required this.price,
    required this.amount,
    required this.total,
    required this.isBid,
  });
}
