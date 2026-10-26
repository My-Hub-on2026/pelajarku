import 'package:intl/intl.dart';

const List<String> dayNames = <String>[
  '',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

String formatDate(DateTime value) =>
    DateFormat('EEE, d MMM yyyy', 'id_ID').format(value);

String formatDateTime(DateTime value) =>
    DateFormat('EEE, d MMM yyyy • HH:mm', 'id_ID').format(value);

String formatShortDate(DateTime value) =>
    DateFormat('d MMM yyyy', 'id_ID').format(value);

String minutesToClock(int minutes) {
  final int hour = minutes ~/ 60;
  final int minute = minutes % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

int timeOfDayToMinutes(int hour, int minute) => hour * 60 + minute;

String titleCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
