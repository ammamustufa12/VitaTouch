import '../core/constants/app_constants.dart';

const monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String greetingFor(DateTime now) {
  if (now.hour < 12) {
    return 'Good morning';
  }
  if (now.hour < 17) {
    return 'Good afternoon';
  }
  return 'Good evening';
}

String providedText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return AppConstants.notProvided;
  }
  return trimmed;
}

String formatAge(int? age) {
  if (age == null) {
    return AppConstants.notProvided;
  }
  if (age == 1) {
    return '1 year';
  }
  return '$age years';
}

String formatDate(DateTime? value) {
  if (value == null) {
    return AppConstants.notProvided;
  }
  final local = value.toLocal();
  return '${local.day} ${monthNames[local.month - 1]} ${local.year}';
}

String formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${formatDate(local)}, ${formatClock(local)}';
}

String formatClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute $suffix';
}

bool isPlausibleBirthDate(DateTime birth, DateTime now) {
  if (birth.isAfter(now)) {
    return false;
  }
  final earliest = DateTime(now.year - 120, now.month, now.day);
  return !birth.isBefore(earliest);
}
