// lib/utils/date_formatter.dart
import 'package.intl/intl.dart';

class DateFormatter {
  static final anomonthday = DateFormat('yyyy-MM-dd');
  static final full = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final hourMinute = DateFormat('HH:mm');

  static String formatAnoMonthDay(DateTime date) {
    return anomonthday.format(date);
  }

  static String formatFull(DateTime date) {
    return full.format(date);
  }

  static String formatHourMinute(DateTime date) {
    return hourMinute.format(date);
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${hours}h ${minutes}m ${seconds}s';
  }
}
