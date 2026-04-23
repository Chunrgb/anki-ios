import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Estatísticas')),
      child: SafeArea(
        child: statsAsync.when(
          data: (stats) => _StatsBody(stats: stats),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final AnkiStats stats;

  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TodayCard(stats: stats),
        const SizedBox(height: 16),
        _StreakCard(streak: stats.streakDays),
        const SizedBox(height: 16),
        _ForecastCard(forecast: stats.forecast),
        const SizedBox(height: 16),
        _RetentionCard(retention: stats.retentionRate),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  final AnkiStats stats;

  const _TodayCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      title: 'Hoje',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: stats.studiedToday.toString(), label: 'Revisados'),
          _StatItem(value: '${stats.studyTimeMinutes}min', label: 'Tempo'),
          _StatItem(value: '${(stats.retentionRate * 100).toStringAsFixed(0)}%', label: 'Retenção'),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      title: 'Sequência',
      child: Row(
        children: [
          const Icon(CupertinoIcons.flame, color: CupertinoColors.systemOrange, size: 32),
          const SizedBox(width: 12),
          Text('$streak dias', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final List<int> forecast;

  const _ForecastCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    final spots = forecast.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return _StatCard(
      title: 'Previsão (30 dias)',
      child: SizedBox(
        height: 150,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10))),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    if (v.toInt() % 7 == 0) return Text('${v.toInt()}d', style: const TextStyle(fontSize: 10));
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: CupertinoColors.activeBlue,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: CupertinoColors.activeBlue.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetentionCard extends StatelessWidget {
  final double retention;

  const _RetentionCard({required this.retention});

  @override
  Widget build(BuildContext context) {
    final pct = (retention * 100).toStringAsFixed(1);
    final color = retention >= 0.9
        ? CupertinoColors.activeGreen
        : retention >= 0.75
            ? CupertinoColors.systemOrange
            : CupertinoColors.destructiveRed;

    return _StatCard(
      title: 'Taxa de Retenção',
      child: Row(
        children: [
          Text('$pct%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'de acertos nos últimos 30 dias',
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.secondaryLabel)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel)),
      ],
    );
  }
}
