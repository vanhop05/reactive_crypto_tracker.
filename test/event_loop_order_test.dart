import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dart Event Loop & Queue Priority Tests', () {
    test('Microtasks execute strictly before Event Queue Futures', () async {
      final List<String> executionLog = [];

      // Schedule Future (Event Queue)
      Future(() {
        executionLog.add('EVENT_QUEUE_FUTURE');
      });

      // Schedule Microtask (Microtask Queue)
      scheduleMicrotask(() {
        executionLog.add('MICROTASK_1');
      });

      // Schedule another Microtask
      Future.microtask(() {
        executionLog.add('MICROTASK_2');
      });

      // Synchronous code execution
      executionLog.add('SYNCHRONOUS_CODE');

      // Allow event loop to process all queues
      await Future.delayed(const Duration(milliseconds: 50));

      // Verifying the absolute order:
      // 1. Synchronous Code
      // 2. Microtasks
      // 3. Event Queue Future
      expect(executionLog, equals([
        'SYNCHRONOUS_CODE',
        'MICROTASK_1',
        'MICROTASK_2',
        'EVENT_QUEUE_FUTURE',
      ]));
    });
  });
}
