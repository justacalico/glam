import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Date, time and number formatting helpers.
abstract final class Format {
  static final _date = DateFormat.yMMMd();
  static final _dateTime = DateFormat.yMMMd().add_Hm();
  static final _compact = NumberFormat.compact();

  /// `3 days ago`-style relative time.
  static String relative(DateTime? time) {
    if (time == null) {
      return '';
    }
    return timeago.format(time, allowFromNow: true);
  }

  /// `Sep 16, 2026`.
  static String date(DateTime? time) =>
      time == null ? '' : _date.format(time.toLocal());

  /// `Sep 16, 2026 4:15 PM`.
  static String dateTime(DateTime? time) =>
      time == null ? '' : _dateTime.format(time.toLocal());

  /// `1.2K` for big numbers, plain for small.
  static String compact(num? value) =>
      value == null ? '0' : _compact.format(value);

  /// `1.4 MB`, `823 KB`.
  static String bytes(int? value) {
    if (value == null || value < 0) {
      return '0 B';
    }
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = value.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final whole = size == size.roundToDouble();
    final text = !whole && size < 10 && unit > 0
        ? size.toStringAsFixed(1)
        : size.round().toString();
    return '$text ${units[unit]}';
  }

  /// `01:23:45` style durations.
  static String duration(double? seconds) {
    if (seconds == null) {
      return '--:--';
    }
    final d = Duration(seconds: seconds.round());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  /// `42 %` with no trailing `.0`.
  static String percent(num? value) {
    if (value == null) {
      return '0%';
    }
    final rounded = value.roundToDouble();
    final isWhole = rounded == rounded.truncateToDouble();
    return '${isWhole ? rounded.toInt() : rounded}%';
  }
}
