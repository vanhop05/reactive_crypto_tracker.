import 'dart:async';

/// Bộ chuyển đổi luồng tùy chỉnh Debounce:
/// Bỏ qua các sự kiện liên tục, chỉ phát sự kiện cuối sau khoảng thời gian [duration].
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
            // Đợi cho đến khi nó kết thúc hoặc đóng lại bộ đếm đang chạy
            if (timer != null && timer!.isActive) {
              // Để bộ đém chạy rồi đóng luồng sau khi kết thúc
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

/// Bộ chuyển đổi luồng tùy chỉnh Throttle:
/// Phát ngay sự kiện đầu tiên, sau đó chặn các sự kiện tiếp theo trong khoảng thời gian [duration].
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

/// Các phương thức mở rộng bổ sung trực tiếp các reactive operator methods vào bất kỳ [Stream] nào
extension ReactiveStreamExtension<T> on Stream<T> {
  /// Debounces các sự kiện trong stream dựa trên [duration]
  Stream<T> debounce(Duration duration) {
    return transform(DebounceStreamTransformer<T>(duration));
  }

  /// Throttles các sự kiện trong stream dựa trên [duration]
  Stream<T> throttle(Duration duration) {
    return transform(ThrottleStreamTransformer<T>(duration));
  }
}
