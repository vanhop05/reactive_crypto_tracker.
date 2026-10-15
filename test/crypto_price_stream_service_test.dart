import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_crypto_tracker/models/market_tick.dart';
import 'package:reactive_crypto_tracker/services/crypto_price_stream_service.dart';

void main() {
  group('CryptoPriceStreamService & Broadcast Stream Test Suite', () {
    late CryptoPriceStreamService service;

    setUp(() {
      service = CryptoPriceStreamService.instance;
    });

    test('Broadcast stream supports multiple concurrent subscribers without error', () async {
      final List<MarketTick> subscriber1Ticks = [];
      final List<MarketTick> subscriber2Ticks = [];

      final sub1 = service.marketStream.listen((tick) {
        subscriber1Ticks.add(tick);
      });

      final sub2 = service.marketStream.listen((tick) {
        subscriber2Ticks.add(tick);
      });

      // Verify stream is active with listeners
      expect(service.activeListenersCount, greaterThanOrEqualTo(1));

      // Wait for at least 1 tick emission
      await Future.delayed(const Duration(milliseconds: 1500));

      // Clean disposal of subscriptions
      await sub1.cancel();
      await sub2.cancel();

      expect(subscriber1Ticks, isNotEmpty);
      expect(subscriber2Ticks, isNotEmpty);
    });

    test('getStreamForSymbol accurately filters ticks for requested coin', () async {
      final List<MarketTick> btcTicks = [];
      final btcSub = service.getStreamForSymbol('BTC').listen((tick) {
        btcTicks.add(tick);
      });

      await Future.delayed(const Duration(milliseconds: 2000));

      for (final tick in btcTicks) {
        expect(tick.symbol, equals('BTC'));
      }

      await btcSub.cancel();
    });
  });
}
