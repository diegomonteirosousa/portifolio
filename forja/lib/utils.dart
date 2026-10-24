import 'dart:math' as math;

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}${math.Random().nextInt(9999)}';

String two(int n) => n.toString().padLeft(2, '0');

/// 3725 -> "1:02:05"; 125 -> "02:05"
String fmtDuration(int totalSec) {
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Ritmo: 332 -> "5:32"
String fmtPace(double? secPerKm) {
  if (secPerKm == null || secPerKm.isInfinite || secPerKm.isNaN) return '--:--';
  if (secPerKm > 3600) return '--:--';
  final s = secPerKm.round();
  return '${s ~/ 60}:${two(s % 60)}';
}

/// 2.5 -> "2,5"; 40.0 -> "40"
String fmtNum(double v, {int decimals = 1}) {
  final isInt = (v - v.roundToDouble()).abs() < 0.001;
  final txt = isInt ? v.round().toString() : v.toStringAsFixed(decimals);
  return txt.replaceAll('.', ',');
}

String fmtKm(double meters) => (meters / 1000).toStringAsFixed(2).replaceAll('.', ',');

/// 1234567 -> "1.234.567"
String fmtInt(num v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

const weekdayShort = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
const weekdayNames = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo'
];
const monthShort = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez'
];

String fmtDate(DateTime d) => '${d.day} ${monthShort[d.month - 1]}';

String fmtDateTime(DateTime d) =>
    '${fmtDate(d)} · ${two(d.hour)}:${two(d.minute)}';

String dayKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String relativeDay(DateTime d) {
  final today = dateOnly(DateTime.now());
  final diff = today.difference(dateOnly(d)).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  if (diff < 7) return '$diff dias atrás';
  return fmtDate(d);
}
