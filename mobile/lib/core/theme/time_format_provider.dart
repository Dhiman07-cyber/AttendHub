import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage.dart';

class TimeFormatNotifier extends StateNotifier<String> {
  final LocalStorage _storage;

  TimeFormatNotifier([LocalStorage? storage])
      : _storage = storage ?? LocalStorage(),
        super(LocalStorage().getTimeFormatSync()) {
    _init();
  }

  Future<void> _init() async {
    final format = await _storage.getTimeFormat();
    if (mounted) {
      state = format;
    }
  }

  Future<void> setFormat(String format) async {
    if (format != '12h' && format != '24h') return;
    state = format;
    await _storage.setTimeFormat(format);
  }

  bool get is24Hour => state == '24h';
}

final timeFormatProvider = StateNotifierProvider<TimeFormatNotifier, String>((ref) {
  return TimeFormatNotifier();
});

/// Formats a time string like "09:00" or "13:30:00" into 12-hour or 24-hour display.
String formatTimeString(String? timeStr, {bool is24Hour = false, bool? is24h}) {
  final use24h = is24h ?? is24Hour;
  if (timeStr == null || timeStr.trim().isEmpty) return '';
  final cleaned = timeStr.trim();
  final parts = cleaned.split(':');
  if (parts.isEmpty) return cleaned;

  final hour = int.tryParse(parts[0]);
  if (hour == null) return cleaned;
  final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  final minuteStr = minute.toString().padLeft(2, '0');

  if (use24h) {
    return '${hour.toString().padLeft(2, '0')}:$minuteStr';
  } else {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayH = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayH:$minuteStr $period';
  }
}

/// Formats an integer hour (e.g. 9 or 13) for column headers.
String formatHourDisplay(int hour, {bool is24Hour = false, bool? is24h}) {
  final use24h = is24h ?? is24Hour;
  if (use24h) {
    return '${hour.toString().padLeft(2, '0')}:00';
  } else {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayH = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayH $period';
  }
}

/// Formats a start and end range like "09:00" and "10:00"
String formatSlotRange(String? start, String? end, {bool is24Hour = false, bool? is24h}) {
  final use24h = is24h ?? is24Hour;
  final startFormatted = formatTimeString(start, is24Hour: use24h);
  final endFormatted = formatTimeString(end, is24Hour: use24h);
  if (startFormatted.isEmpty && endFormatted.isEmpty) return '';
  if (endFormatted.isEmpty) return startFormatted;
  if (startFormatted.isEmpty) return endFormatted;
  return '$startFormatted – $endFormatted';
}

