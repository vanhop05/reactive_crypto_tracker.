/// Model representing an order book depth entry (Bid/Ask)
class OrderBookEntry {
  final double price;
  final double amount;
  final double total;
  final bool isBid; // true for buy (bid), false for sell (ask)

  const OrderBookEntry({
    required this.price,
    required this.amount,
    required this.total,
    required this.isBid,
  });
}
