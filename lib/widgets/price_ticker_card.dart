import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/crypto_asset.dart';
import '../models/market_tick.dart';
import 'mini_price_chart.dart';

/// Card displaying real-time cryptocurrency info with pulse animation on tick change.
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

class _PriceTickerCardState extends State<PriceTickerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _flashColorAnimation;
  double _lastSeenPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _lastSeenPrice = widget.asset.currentPrice;

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _flashColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.transparent,
    ).animate(_flashController);
  }

  @override
  void didUpdateWidget(covariant PriceTickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latestTick != null &&
        widget.latestTick!.symbol == widget.asset.symbol &&
        widget.latestTick!.price != _lastSeenPrice) {
      final isUp = widget.latestTick!.price > _lastSeenPrice;
      _lastSeenPrice = widget.latestTick!.price;

      final highlightColor = isUp
          ? const Color(0xFF10B981).withOpacity(0.25)
          : const Color(0xFFEF4444).withOpacity(0.25);

      _flashColorAnimation = ColorTween(
        begin: highlightColor,
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: _flashController,
        curve: Curves.easeOutQuad,
      ));

      _flashController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
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

    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _flashColorAnimation.value != Colors.transparent
                ? Color.alphaBlend(
                    _flashColorAnimation.value ?? Colors.transparent,
                    Theme.of(context).cardTheme.color ?? const Color(0xFF151B26),
                  )
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _flashColorAnimation.value != null &&
                      _flashColorAnimation.value != Colors.transparent
                  ? (isPositive
                      ? const Color(0xFF10B981).withOpacity(0.6)
                      : const Color(0xFFEF4444).withOpacity(0.6))
                  : Colors.white.withOpacity(0.06),
              width: 1.2,
            ),
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon / Symbol Badge
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
                // Name & Symbol
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
                // Mini Sparkline
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
                // Price & Percentage
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
