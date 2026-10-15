import 'package:flutter/material.dart';

/// Represents a single recorded execution step in the Event Loop demonstration.
class EventLoopStep {
  final int id;
  final String queueType; // 'Synchronous Stack', 'Microtask Queue', 'Event Queue (Future/Timer)'
  final String label;
  final String description;
  final int order;
  final int timestampMicroseconds;
  final Color tagColor;
  final IconData icon;

  const EventLoopStep({
    required this.id,
    required this.queueType,
    required this.label,
    required this.description,
    required this.order,
    required this.timestampMicroseconds,
    required this.tagColor,
    required this.icon,
  });
}
