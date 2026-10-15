import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_crypto_tracker/core/transformers/stream_transformers.dart';

void main() {
  group('Custom Stream Transformers Test Suite', () {
    test('DebounceStreamTransformer emits only the latest event after quiet period', () async {
      final controller = StreamController<String>();
      final debouncedStream = controller.stream.debounce(const Duration(milliseconds: 100));

      final List<String> receivedValues = [];
      final sub = debouncedStream.listen(receivedValues.add);

      // Rapidly add 3 items within 50ms (less than 100ms debounce window)
      controller.add('A');
      await Future.delayed(const Duration(milliseconds: 20));
      controller.add('B');
      await Future.delayed(const Duration(milliseconds: 20));
      controller.add('C');

      // Check before debounce completes: nothing should be emitted yet
      expect(receivedValues, isEmpty);

      // Wait for debounce period to expire (100ms + buffer)
      await Future.delayed(const Duration(milliseconds: 150));

      // Only 'C' should have been emitted!
      expect(receivedValues, equals(['C']));

      await sub.cancel();
      await controller.close();
    });

    test('ThrottleStreamTransformer emits the first event and blocks subsequent ones in window', () async {
      final controller = StreamController<int>();
      final throttledStream = controller.stream.throttle(const Duration(milliseconds: 100));

      final List<int> receivedValues = [];
      final sub = throttledStream.listen(receivedValues.add);

      // Emit item 1
      controller.add(1);
      // Immediately emit item 2 and 3 within throttle window
      controller.add(2);
      controller.add(3);

      await Future.delayed(const Duration(milliseconds: 20));
      // Only 1 should be received immediately
      expect(receivedValues, equals([1]));

      // Wait for throttle window to pass
      await Future.delayed(const Duration(milliseconds: 120));

      // Emit item 4 after window
      controller.add(4);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(receivedValues, equals([1, 4]));

      await sub.cancel();
      await controller.close();
    });
  });
}
