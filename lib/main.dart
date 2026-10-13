String fmtDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String monthYear(String input) {
  final match = RegExp(
    r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
  ).firstMatch(input.trim());

  if (match == null) return '';

  final day = int.tryParse(match.group(1)!) ?? 0;
  final month = int.tryParse(match.group(2)!) ?? 0;
  final year = int.tryParse(match.group(3)!) ?? 0;

  if (year < 1 || month < 1 || month > 12 || day < 1) {
    return '';
  }

  final date = DateTime(year, month, day);

  // Reject impossible calendar dates.
  if (date.year != year ||
      date.month != month ||
      date.day != day) {
    return '';
  }

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  return '${months[month - 1]}<d>${year}';
}