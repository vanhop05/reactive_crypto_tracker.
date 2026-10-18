import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/crypto_asset.dart';
import '../models/market_tick.dart';
import 'mini_price_chart.dart';

/// Thẻ hiển thị một đồng coin trong danh sách thị trường.
/// Tự động nhấp nháy màu xanh (khi tăng giá) hoặc màu đỏ (khi giảm giá) mỗi khi nhận được bước giá mới từ Stream.
class PriceTickerCard extends StatefulWidget {
  final CryptoAsset asset;
  final MarketTick? latestTick;
  final VoidCallback onTap;

  const PriceTickerCard({
    super.key,
    required this.asset,
    required this.latestTick,
    required this.onTap,
  });

  @override
  State<PriceTickerCard> createState() => _PriceTickerCardState();
}

class _PriceTickerCardState extends State<PriceTickerCard> {
  Color _flashColor = Colors.transparent;
  double _lastSeenPrice = 0.0;
  Timer? _resetFlashTimer;

  @override
  void initState() {
    super.initState();
    _lastSeenPrice = widget.asset.currentPrice;
  }

  /// Khi Widget cha truyền dữ liệu tick mới từ StreamBuilder xuống
  @override
  void didUpdateWidget(covariant PriceTickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final tick = widget.latestTick;
    if (tick != null && tick.symbol == widget.asset.symbol && tick.price != _lastSeenPrice) {
      final isUp = tick.price > _lastSeenPrice;
      _lastSeenPrice = tick.price;

      // Đổi màu viền/nền thẻ để tạo hiệu ứng nhấp nháy trực quan
      setState(() {
        _flashColor = isUp
            ? const Color(0xFF10B981).withOpacity(0.25) // Màu xanh tăng giá
            : const Color(0xFFEF4444).withOpacity(0.25); // Màu đỏ giảm giá
      });

      // Tự động trả về màu trong suốt sau 350ms
      _resetFlashTimer?.cancel();
      _resetFlashTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _flashColor = Colors.transparent;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _resetFlashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: widget.asset.currentPrice < 1.0 ? 4 : 2,
    );

    final isPositive = widget.asset.isPositive;
    final changePrefix = isPositive ? '+' : '';
    final hasFlash = _flashColor != Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: hasFlash ? _flashColor : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFlash
              ? (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))
              : Colors.white.withOpacity(0.06),
          width: hasFlash ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Khung hiển thị ký hiệu đồng coin
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Center(
                    child: Text(
                      widget.asset.symbol.substring(0, widget.asset.symbol.length > 3 ? 3 : widget.asset.symbol.length),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tên và phân loại coin
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.asset.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            widget.asset.symbol,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.asset.category,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Biểu đồ đường mini (Sparkline)
                Expanded(
                  flex: 3,
                  child: Center(
                    child: MiniPriceChart(
                      dataPoints: widget.asset.sparkline,
                      isPositive: isPositive,
                      height: 38,
                      width: 80,
                    ),
                  ),
                ),

                // Giá và phần trăm thay đổi
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(widget.asset.currentPrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? const Color(0xFF10B981).withOpacity(0.18)
                              : const Color(0xFFEF4444).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$changePrefix${widget.asset.change24h.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
