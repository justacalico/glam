import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/utils/extensions.dart';

void main() {
  group('initials', () {
    test('two-part name', () {
      expect('Calico Cat'.initials, 'CC');
    });

    test('dotted username', () {
      expect('jane.doe'.initials, 'JD');
    });

    test('single word takes two letters', () {
      expect('glam'.initials, 'GL');
    });

    test('single letter stays', () {
      expect('x'.initials, 'X');
    });

    test('empty is a placeholder', () {
      expect(' '.initials, '?');
    });
  });

  group('capitalized', () {
    test('capitalizes the first letter', () {
      expect('opened'.capitalized, 'Opened');
      expect(''.capitalized, '');
    });
  });

  group('isToday', () {
    test('today and not-today', () {
      expect(DateTime.now().isToday, isTrue);
      expect(DateTime.now().subtract(const Duration(days: 1)).isToday, isFalse);
    });
  });
}
