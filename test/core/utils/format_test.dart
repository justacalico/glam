import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/utils/format.dart';

void main() {
  group('bytes', () {
    test('formats each unit', () {
      expect(Format.bytes(0), '0 B');
      expect(Format.bytes(512), '512 B');
      expect(Format.bytes(2048), '2 KB');
      expect(Format.bytes(1536), '1.5 KB');
      expect(Format.bytes(5 * 1024 * 1024), '5 MB');
      expect(Format.bytes(null), '0 B');
      expect(Format.bytes(-5), '0 B');
    });
  });

  group('duration', () {
    test('formats seconds', () {
      expect(Format.duration(0), '00:00');
      expect(Format.duration(65), '01:05');
      expect(Format.duration(3725), '1:02:05');
      expect(Format.duration(null), '--:--');
    });
  });

  group('percent', () {
    test('formats whole and fractional values', () {
      expect(Format.percent(42), '42%');
      expect(Format.percent(33.4), '33%');
      expect(Format.percent(null), '0%');
    });
  });

  group('compact', () {
    test('small numbers stay plain', () {
      expect(Format.compact(42), '42');
    });

    test('big numbers abbreviate', () {
      expect(Format.compact(1500), '1.5K');
      expect(Format.compact(2500000), '2.5M');
    });

    test('null is zero', () {
      expect(Format.compact(null), '0');
    });
  });

  group('relative', () {
    test('null is empty', () {
      expect(Format.relative(null), '');
    });

    test('recent times are relative', () {
      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
      expect(Format.relative(fiveMinAgo), contains('ago'));
    });
  });

  group('date', () {
    test('formats a date', () {
      expect(Format.date(DateTime(2026, 9, 16)), 'Sep 16, 2026');
    });

    test('null is empty', () {
      expect(Format.date(null), '');
      expect(Format.dateTime(null), '');
    });
  });
}
