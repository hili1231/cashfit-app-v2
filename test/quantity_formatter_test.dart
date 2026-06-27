import 'package:flutter_test/flutter_test.dart';
import 'package:cashfit/utils/quantity_formatter.dart';

void main() {
  group('QuantityFormatter Tests', () {
    test('Formats integers correctly', () {
      expect(QuantityFormatter.format(2.0), '2');
      expect(QuantityFormatter.format(10.0), '10');
    });

    test('Formats common fractions correctly without raw floating decimals', () {
      expect(QuantityFormatter.format(1.5), '1 1/2');
      expect(QuantityFormatter.format(0.25), '1/4');
      expect(QuantityFormatter.format(0.75), '3/4');
      expect(QuantityFormatter.format(0.333), '1/3');
    });

    test('Formats macros and calories safely', () {
      expect(QuantityFormatter.formatMacro(25.4, unit: 'g'), '25 g');
      expect(QuantityFormatter.formatCalories(450.8), '451 kcal');
    });
  });
}
