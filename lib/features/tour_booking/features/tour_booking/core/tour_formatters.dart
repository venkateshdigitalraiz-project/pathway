import 'package:intl/intl.dart';

class TourFormatters {
  TourFormatters._();

  static String rupee(num value) =>
      '₹${NumberFormat.decimalPattern('en_IN').format(value.round())}';

  /// 2568 -> "2,568"
  static String reviewsFull(int count) =>
      NumberFormat.decimalPattern('en_IN').format(count);

  /// 2568 -> "2.5k"
  static String reviewsShort(int count) {
    if (count >= 1000) {
      final k = (count / 1000).toStringAsFixed(1).replaceAll('.0', '');
      return '${k}k';
    }
    return '$count';
  }

  static String dateLong(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String weekday(DateTime d) => DateFormat('EEE').format(d);

  /// "15 Nov - 20 Nov 2025"
  static String range(DateTime start, DateTime end) {
    if (start.year == end.year) {
      return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
    }
    return '${dateLong(start)} - ${dateLong(end)}';
  }

  static String travellers(int n) => n == 1 ? '1 Traveller' : '$n Travellers';
  static String adults(int n) => n == 1 ? '1 Adult' : '$n Adults';
}
