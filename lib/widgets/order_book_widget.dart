import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_book_entry.dart';

/// Hiển thị biểu đồ lệnh mua so với lệnh bán theo thời gian thực 
class OrderBookWidget extends StatelessWidget {
  final List<OrderBookEntry> entries;

  const OrderBookWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final numberFormatter = NumberFormat('#,##0.000');

    final bids = entries.where((e) => e.isBid).toList();
    final asks = entries.where((e) => !e.isBid).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sổ Lệnh Thời Gian Thực (Order Book)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'STREAM CẬP NHẬT',
                  style: TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'MUA (BIDS)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ),
              Expanded(
                child: Text(
                  'BÁN (ASKS)',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bids.length > asks.length ? asks.length : bids.length,
            itemBuilder: (context, index) {
              final bid = bids[index];
              final ask = asks[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Bid side
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currencyFormatter.format(bid.price),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF10B981),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            numberFormatter.format(bid.amount),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Ask side
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            numberFormatter.format(ask.amount),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            currencyFormatter.format(ask.price),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFEF4444),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
