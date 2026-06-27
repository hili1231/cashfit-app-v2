import 'package:intl/intl.dart';

class QuantityFormatter {
  /// Formats a raw double quantity into a clean, human-readable string.
  /// Converts numbers close to integers into whole numbers (e.g. 2.0 -> 2),
  /// common fractions into clean decimals (e.g. 1.5, 0.25, 0.75),
  /// and rounds other decimals to at most 1 decimal place.
  static String format(double value) {
    if (value <= 0) return '0';

    // If practically an integer
    if ((value - value.round()).abs() < 0.01) {
      return value.round().toString();
    }

    // Common fraction check
    double decimalPart = value - value.floor();
    if ((decimalPart - 0.25).abs() < 0.02) {
      return '${value.floor() == 0 ? '' : '${value.floor()} '}1/4'.trim();
    } else if ((decimalPart - 0.33).abs() < 0.03 || (decimalPart - 0.333).abs() < 0.03) {
      return '${value.floor() == 0 ? '' : '${value.floor()} '}1/3'.trim();
    } else if ((decimalPart - 0.5).abs() < 0.02) {
      return '${value.floor() == 0 ? '' : '${value.floor()} '}1/2'.trim();
    } else if ((decimalPart - 0.66).abs() < 0.03 || (decimalPart - 0.67).abs() < 0.03) {
      return '${value.floor() == 0 ? '' : '${value.floor()} '}2/3'.trim();
    } else if ((decimalPart - 0.75).abs() < 0.02) {
      return '${value.floor() == 0 ? '' : '${value.floor()} '}3/4'.trim();
    }

    // Standard single decimal rounding
    final formatter = NumberFormat("0.#", "en_US");
    return formatter.format(value);
  }

  /// Formats macronutrient or calorie counts safely
  static String formatMacro(num value, {String unit = 'g'}) {
    if (value <= 0) return '0 $unit';
    return '${value.round()} $unit';
  }

  /// Formats calorie counts safely
  static String formatCalories(num value) {
    if (value <= 0) return '0 kcal';
    return '${value.round()} kcal';
  }
}
