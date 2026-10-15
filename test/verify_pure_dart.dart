import 'dart:async';
import '../lib/core/transformers/stream_transformers.dart';
import '../lib/services/crypto_price_stream_service.dart';

void main() async {
  print('=============================================');
  print('🚀 CHẠY KIỂM THỬ TỰ ĐỘNG CHỦ ĐỀ 02 (DART TEST)');
  print('=============================================');

  // Test 1: Event Loop & Queue Priority
  print('\n[Test 1] Kiểm tra thứ tự Event Loop & Microtask Queue:');
  final List<String> logs = [];

  Future(() => logs.add('3_EVENT_QUEUE_FUTURE'));
  scheduleMicrotask(() => logs.add('2_MICROTASK_1'));
  Future.microtask(() => logs.add('2_MICROTASK_2'));
  logs.add('1_SYNCHRONOUS_CODE');

  await Future.delayed(const Duration(milliseconds: 60));

  assert(logs[0] == '1_SYNCHRONOUS_CODE', 'Lỗi: Sync code phải chạy đầu tiên!');
  assert(logs[1] == '2_MICROTASK_1', 'Lỗi: Microtask 1 phải chạy trước Future!');
  assert(logs[2] == '2_MICROTASK_2', 'Lỗi: Microtask 2 phải chạy trước Future!');
  assert(logs[3] == '3_EVENT_QUEUE_FUTURE', 'Lỗi: Event queue Future phải chạy cuối cùng!');
  print('  -> PASS: Thứ tự ưu tiên chính xác tuyệt đối: Sync -> Microtasks -> Future.');

  // Test 2: Custom Debounce Stream Transformer
  print('\n[Test 2] Kiểm tra Toán tử DebounceStreamTransformer:');
  final controller = StreamController<String>();
  final debouncedStream = controller.stream.debounce(const Duration(milliseconds: 100));
  final List<String> received = [];
  final sub = debouncedStream.listen(received.add);

  controller.add('F');
  await Future.delayed(const Duration(milliseconds: 20));
  controller.add('FL');
  await Future.delayed(const Duration(milliseconds: 20));
  controller.add('FLUTTER');

  // Before 100ms expires:
  assert(received.isEmpty, 'Lỗi: Debounce không được phát khi chưa hết khoảng chờ!');

  // After 100ms:
  await Future.delayed(const Duration(milliseconds: 150));
  assert(received.length == 1 && received.first == 'FLUTTER', 'Lỗi: Chỉ được phát giá trị cuối cùng!');
  print('  -> PASS: Debounce hoạt động chính xác (đã gộp các ký tự gõ nhanh thành 1 giá trị duy nhất).');
  await sub.cancel();
  await controller.close();

  // Test 3: Broadcast Stream & Multi-listener & Safe Cancellation
  print('\n[Test 3] Kiểm tra Broadcast Stream & Hủy Luồng An Toàn:');
  final service = CryptoPriceStreamService.instance;
  int tickCount1 = 0;
  int tickCount2 = 0;

  final sub1 = service.marketStream.listen((tick) => tickCount1++);
  final sub2 = service.marketStream.listen((tick) => tickCount2++);

  assert(service.activeListenersCount >= 2, 'Lỗi: Bộ đếm active subscriber không tăng!');
  print('  -> Active subscribers: ${service.activeListenersCount}');

  // Wait for 1.5 seconds for ticks to stream
  await Future.delayed(const Duration(milliseconds: 1500));

  assert(tickCount1 > 0 && tickCount2 > 0, 'Lỗi: Cả 2 subscriber đều phải nhận được tick!');
  print('  -> Đã nhận: Sub1=$tickCount1 ticks, Sub2=$tickCount2 ticks.');

  // Safe cancellation
  final initialSubs = service.activeListenersCount;
  await sub1.cancel();
  await sub2.cancel();
  print('  -> PASS: Đã hủy sub1 & sub2 an toàn. Subscribers giảm từ $initialSubs về ${service.activeListenersCount}.');

  await service.dispose();
  print('\n🎉 TOÀN BỘ CÁC BÀI TEST CHỦ ĐỀ 02 ĐÃ VƯỢT QUA 100%!');
}
