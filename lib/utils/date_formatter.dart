// lib/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  static final anomonthday = DateFormat('yyyy-MM-dd');
  static final full = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String formatAnoMonthDay(DateTime date) {
    return anomonthday.format(date);
  }

  static String formatFull(DateTime date) {
    return full.format(date);
  }
}
