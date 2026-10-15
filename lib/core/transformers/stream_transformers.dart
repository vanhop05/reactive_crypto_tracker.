import 'dart:async';

/// Custom Stream Transformer implementing the Debounce pattern.
/// Drops values that are followed by newer values within [duration].
class DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;

  DebounceStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;
    Timer? timer;

    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          (data) {
            timer?.cancel();
            timer = Timer(duration, () {
              if (!controller!.isClosed) {
                controller.add(data);
              }
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller!.isClosed) {
              controller.addError(error, stackTrace);
            }
          },
          onDone: () {
            // If there's an ongoing timer, wait until it completes or close
            if (timer != null && timer!.isActive) {
              // Let the pending timer finish before closing
              timer = Timer(duration, () {
                if (!controller!.isClosed) {
                  controller.close();
                }
              });
            } else {
              if (!controller!.isClosed) {
                controller.close();
              }
            }
          },
          cancelOnError: false,
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () async {
        timer?.cancel();
        await subscription?.cancel();
      },
      sync: false,
    );

    return controller.stream;
  }
}

/// Custom Stream Transformer implementing the Throttle pattern.
/// Emits the first item, then suppresses emissions for [duration].
class ThrottleStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;

  ThrottleStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;
    bool isThrottled = false;
    Timer? throttleTimer;

    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          (data) {
            if (!isThrottled) {
              isThrottled = true;
              if (!controller!.isClosed) {
                controller.add(data);
              }
              throttleTimer?.cancel();
              throttleTimer = Timer(duration, () {
                isThrottled = false;
              });
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller!.isClosed) {
              controller.addError(error, stackTrace);
            }
          },
          onDone: () {
            throttleTimer?.cancel();
            if (!controller!.isClosed) {
              controller.close();
            }
          },
          cancelOnError: false,
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () async {
        throttleTimer?.cancel();
        await subscription?.cancel();
      },
      sync: false,
    );

    return controller.stream;
  }
}

/// Extension methods adding reactive operator methods directly to any [Stream].
extension ReactiveStreamExtension<T> on Stream<T> {
  /// Debounces stream events by the specified [duration].
  Stream<T> debounce(Duration duration) {
    return transform(DebounceStreamTransformer<T>(duration));
  }

  /// Throttles stream events by the specified [duration].
  Stream<T> throttle(Duration duration) {
    return transform(ThrottleStreamTransformer<T>(duration));
  }
}
