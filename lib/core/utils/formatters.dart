import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat =
      NumberFormat.currency(symbol: '\u09F3', decimalDigits: 0);
  static final _numberFormat = NumberFormat('#,##0');
  static final _percentFormat = NumberFormat('##.#');
  static final _dateFullFormat = DateFormat('dd MMMM, yyyy');
  static final _dateShortFormat = DateFormat('dd MMM, yyyy');
  static final _dateIsoFormat = DateFormat('yyyy-MM-dd');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _dateTimeFormat = DateFormat('dd MMM, yyyy hh:mm a');

  static String currency(double amount) => _currencyFormat.format(amount);
  static String number(int number) => _numberFormat.format(number);
  static String percent(double value) => '${_percentFormat.format(value)}%';
  static String dateFull(DateTime date) => _dateFullFormat.format(date);
  static String dateShort(DateTime date) => _dateShortFormat.format(date);
  static String dateIso(DateTime date) => _dateIsoFormat.format(date);
  static String time(DateTime date) => _timeFormat.format(date);
  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  static String duration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
    }
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  static String audioDuration(int seconds) {
    final d = Duration(seconds: seconds);
    if (d.inHours > 0) {
      return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
    }
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  static String twoDigits(int n) => n.toString().padLeft(2, '0');
}
