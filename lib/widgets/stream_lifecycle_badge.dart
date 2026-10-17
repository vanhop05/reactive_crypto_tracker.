import 'package:flutter/material.dart';

/// Tiện ích giám sát trực quan hiển thị trạng thái hoạt động và vòng đời của reactive stream
class StreamLifecycleBadge extends StatelessWidget {
  final int activeListeners;
  final bool isSafeDisposed;
  final String label;

  const StreamLifecycleBadge({
    super.key,
    required this.activeListeners,
    this.isSafeDisposed = false,
    this.label = 'Broadcast Stream',
  });
  // Giao diện trạng thái hoạt động của stream
  @override
  Widget build(BuildContext context) {
    final isListening = activeListeners > 0 && !isSafeDisposed;
    final statusColor = isSafeDisposed
        ? const Color(0xFF10B981)
        : (isListening ? const Color(0xFF06B6D4) : Colors.grey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isSafeDisposed
                ? 'HỦY LUỒNG AN TOÀN (0 LEAK)'
                : '$label: $activeListeners SUBSCRIBER${activeListeners > 1 ? 'S' : ''}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
