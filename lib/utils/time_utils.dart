class TimeUtils {
  /// Transforms '14:30:00' to a 24-hour formatted string '14:30'
  static String formatTime24h(String dbTime) {
    if (dbTime.isEmpty) return '';
    final parts = dbTime.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Formats a time string to 12-hour AM/PM string ('14:30' -> '02:30 PM')
  static String formatTime12h(String time24h) {
    if (time24h.isEmpty) return '';
    final parts = time24h.split(':');
    final hour24 = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final period = hour24 >= 12 ? 'PM' : 'AM';
    final normalizedHour = hour24 % 12 == 0 ? 12 : hour24 % 12;

    return '${normalizedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Extracts the period (AM/PM) from a 24-hour time string like '14:30:00'
  static String timePeriod(String dbTime) {
    if (dbTime.isEmpty) return 'AM';
    final h = int.tryParse(dbTime.split(':').first) ?? 0;
    return h < 12 ? 'AM' : 'PM';
  }

  /// Calculates duration in minutes between two 24h time strings ('14:00:00' and '15:30:00')
  static int calcDuration(String startTime, String endTime) {
    if (startTime.isEmpty || endTime.isEmpty) return 60;
    final sp = startTime.split(':');
    final ep = endTime.split(':');
    final startMin = (int.tryParse(sp.first) ?? 0) * 60 + (sp.length > 1 ? (int.tryParse(sp[1]) ?? 0) : 0);
    final endMin = (int.tryParse(ep.first) ?? 0) * 60 + (ep.length > 1 ? (int.tryParse(ep[1]) ?? 0) : 0);
    final diff = endMin - startMin;
    return diff > 0 ? diff : 60;
  }

  /// Formats the time range into a 12-hour AM/PM string given a start time and duration
  /// Example: '14:30', 60 -> '02:30 PM - 03:30 PM'
  static String formatTimeRange12h(String startTime24h, int durationMin) {
    if (startTime24h.isEmpty) return '';
    final start12h = formatTime12h(startTime24h);
    
    final parts = startTime24h.split(':');
    final hour24 = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final startMinutes = hour24 * 60 + minute;
    final endMinutes = startMinutes + durationMin;
    final endHour24 = (endMinutes ~/ 60) % 24;
    final endMinute = endMinutes % 60;
    
    final endPeriod = endHour24 >= 12 ? 'PM' : 'AM';
    final normalizedHour = endHour24 % 12 == 0 ? 12 : endHour24 % 12;
    
    final end12h = '${normalizedHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} $endPeriod';

    return '$start12h - $end12h';
  }

  /// Combines a Date and a 24h time string ('14:30') into a DateTime
  static DateTime? combineDateAndTime(DateTime? sessionDate, String time24h) {
    if (sessionDate == null || time24h.isEmpty) return null;
    final parts = time24h.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    return DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      hour,
      minute,
    );
  }
}
