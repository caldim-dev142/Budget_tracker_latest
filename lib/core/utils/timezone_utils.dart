import 'package:intl/intl.dart';

/// Common timezone definitions — name, display label, UTC offset in minutes.
class AppTimezone {
  final String id;       // e.g. 'Asia/Kolkata'
  final String label;    // e.g. 'IST (UTC+5:30)'
  final int offsetMinutes; // e.g. 330

  const AppTimezone({
    required this.id,
    required this.label,
    required this.offsetMinutes,
  });
}

const List<AppTimezone> kTimezones = [
  AppTimezone(id: 'UTC',            label: 'UTC (UTC+0:00)',         offsetMinutes: 0),
  AppTimezone(id: 'Europe/London',  label: 'GMT/BST (UTC+0:00)',     offsetMinutes: 0),
  AppTimezone(id: 'Europe/Paris',   label: 'CET (UTC+1:00)',         offsetMinutes: 60),
  AppTimezone(id: 'Europe/Athens',  label: 'EET (UTC+2:00)',         offsetMinutes: 120),
  AppTimezone(id: 'Asia/Riyadh',    label: 'AST (UTC+3:00)',         offsetMinutes: 180),
  AppTimezone(id: 'Asia/Dubai',     label: 'GST (UTC+4:00)',         offsetMinutes: 240),
  AppTimezone(id: 'Asia/Kolkata',   label: 'IST (UTC+5:30)',         offsetMinutes: 330),
  AppTimezone(id: 'Asia/Dhaka',     label: 'BST (UTC+6:00)',         offsetMinutes: 360),
  AppTimezone(id: 'Asia/Bangkok',   label: 'ICT (UTC+7:00)',         offsetMinutes: 420),
  AppTimezone(id: 'Asia/Singapore', label: 'SGT (UTC+8:00)',         offsetMinutes: 480),
  AppTimezone(id: 'Asia/Tokyo',     label: 'JST (UTC+9:00)',         offsetMinutes: 540),
  AppTimezone(id: 'Australia/Sydney',label: 'AEST (UTC+10:00)',      offsetMinutes: 600),
  AppTimezone(id: 'Pacific/Auckland',label: 'NZST (UTC+12:00)',      offsetMinutes: 720),
  AppTimezone(id: 'Pacific/Midway', label: 'SST (UTC-11:00)',        offsetMinutes: -660),
  AppTimezone(id: 'Pacific/Honolulu',label: 'HST (UTC-10:00)',       offsetMinutes: -600),
  AppTimezone(id: 'America/Anchorage',label: 'AKST (UTC-9:00)',      offsetMinutes: -540),
  AppTimezone(id: 'America/Los_Angeles',label: 'PST/PDT (UTC-8:00)',  offsetMinutes: -480),
  AppTimezone(id: 'America/Denver', label: 'MST/MDT (UTC-7:00)',     offsetMinutes: -420),
  AppTimezone(id: 'America/Chicago',label: 'CST/CDT (UTC-6:00)',     offsetMinutes: -360),
  AppTimezone(id: 'America/New_York',label: 'EST/EDT (UTC-5:00)',    offsetMinutes: -300),
  AppTimezone(id: 'America/Caracas',label: 'VET (UTC-4:00)',         offsetMinutes: -240),
  AppTimezone(id: 'America/Sao_Paulo',label: 'BRT (UTC-3:00)',       offsetMinutes: -180),
  AppTimezone(id: 'Atlantic/South_Georgia',label: 'GST (UTC-2:00)',  offsetMinutes: -120),
  AppTimezone(id: 'Atlantic/Azores',label: 'AZOT (UTC-1:00)',        offsetMinutes: -60),
];

/// Converts a [DateTime] (assumed UTC) to the given [offsetMinutes] timezone.
DateTime toTimezone(DateTime utc, int offsetMinutes) {
  final asUtc = utc.isUtc ? utc : DateTime.utc(
    utc.year, utc.month, utc.day,
    utc.hour, utc.minute, utc.second, utc.millisecond,
  );
  return asUtc.add(Duration(minutes: offsetMinutes));
}

/// Formats a [DateTime] to 'dd MMM yyyy' in the given timezone offset.
String formatDate(DateTime dt, int offsetMinutes) {
  final local = toTimezone(dt, offsetMinutes);
  return DateFormat('dd MMM yyyy').format(local);
}

/// Formats a [DateTime] to 'dd MMM yyyy, hh:mm a' in the given timezone offset.
String formatDateTime(DateTime dt, int offsetMinutes) {
  final local = toTimezone(dt, offsetMinutes);
  return DateFormat('dd MMM yyyy, hh:mm a').format(local);
}

/// Formats a [DateTime] to 'dd/MM/yyyy' (short) in the given timezone offset.
String formatDateShort(DateTime dt, int offsetMinutes) {
  final local = toTimezone(dt, offsetMinutes);
  return '${local.day}/${local.month}/${local.year}';
}

/// Returns 'Today', 'Yesterday', or 'dd MMM yyyy' relative to now in timezone.
String formatDateRelative(DateTime dt, int offsetMinutes) {
  final local = toTimezone(dt, offsetMinutes);
  final now = toTimezone(DateTime.now().toUtc(), offsetMinutes);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('dd MMM yyyy').format(local);
}
