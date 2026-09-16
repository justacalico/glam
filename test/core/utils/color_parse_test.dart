import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/utils/color_parse.dart';

void main() {
  group('parseHexColor', () {
    test('parses #rrggbb', () {
      expect(parseHexColor('#FF6D26'), const Color(0xFFFF6D26));
    });

    test('parses bare rrggbb', () {
      expect(parseHexColor('00FF00'), const Color(0xFF00FF00));
    });

    test('expands #rgb', () {
      expect(parseHexColor('#F60'), const Color(0xFFFF6600));
    });

    test('rejects garbage', () {
      expect(parseHexColor(null), isNull);
      expect(parseHexColor(''), isNull);
      expect(parseHexColor('#12'), isNull);
      expect(parseHexColor('not-a-color'), isNull);
      expect(parseHexColor('#GGGGGG'), isNull);
    });
  });

  group('contrastingText', () {
    test('dark on light, light on dark', () {
      expect(contrastingText(Colors.white), const Color(0xFF1B1B23));
      expect(contrastingText(Colors.black), const Color(0xFFF1F1F6));
    });
  });
}
