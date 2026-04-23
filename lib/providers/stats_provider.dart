import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/anki_service.dart';

class AnkiStats {
  final int studiedToday;
  final int studyTimeMinutes;
  final double retentionRate;
  final int streakDays;
  final List<int> forecast;

  const AnkiStats({
    this.studiedToday = 0,
    this.studyTimeMinutes = 0,
    this.retentionRate = 0.0,
    this.streakDays = 0,
    this.forecast = const [],
  });
}

final statsProvider = FutureProvider<AnkiStats>((ref) async {
  return AnkiService.instance.getStats();
});
