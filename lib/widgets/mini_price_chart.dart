import 'dart:math';
import 'package:flutter/material.dart';

/// Vẽ biểu đồ đường tối giản cho dữ liệu lịch sử giá tiền điện tử theo thời gian thực.
class MiniPriceChart extends StatelessWidget {
  final List<double> dataPoints;
  final bool isPositive;
  final double height;
  final double width;

  const MiniPriceChart({
    super.key,
    required this.dataPoints,
    required this.isPositive,
    this.height = 48,
    this.width = 110,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          points: dataPoints,
          lineColor: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      ),
    );
  }
}

// Vẽ biểu đồ đường tối giản dựa trên danh sách điểm dữ liệu và màu sắc đường
class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;

  _SparklinePainter({
    required this.points,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minVal = points.reduce(min);
    final maxVal = points.reduce(max);
    final range = maxVal - minVal == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final normY = (points[i] - minVal) / range;
      final x = i * stepX;
      final y = size.height - (normY * (size.height - 8)) - 4;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Thêm gradient cho đường biểu đồ
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withOpacity(0.30),
        lineColor.withOpacity(0.0),
      ],
    );
    // Vẽ phần dưới đường biểu đồ
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    // Vễ đường biểu đồ
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
