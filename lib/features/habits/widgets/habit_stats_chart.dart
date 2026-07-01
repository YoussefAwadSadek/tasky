import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/habit_providers.dart';

/// A bar chart of a habit's completions over a window of days, built on
/// fl_chart's [BarChart].
///
/// Completed days render as a full-height accent bar; missed days render as a
/// faint stub so the cadence is readable at a glance.
class HabitStatsChart extends StatelessWidget {
  const HabitStatsChart({
    required this.bars,
    required this.color,
    required this.range,
    super.key,
  });

  final List<HabitBar> bars;
  final Color color;
  final StatsRange range;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color faint = theme.colorScheme.surfaceContainerHighest;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: 1,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItem:
                (BarChartGroupData group, int _, BarChartRodData rod, int __) {
              final HabitBar bar = bars[group.x];
              return BarTooltipItem(
                '${DateFormat('EEE, d MMM').format(bar.date)}\n'
                '${bar.completed ? 'Done' : 'Missed'}',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= bars.length) {
                  return const SizedBox.shrink();
                }
                // Reduce clutter on the monthly view: label ~5 ticks.
                final int step = range == StatsRange.week ? 1 : 6;
                if (index % step != 0 && index != bars.length - 1) {
                  return const SizedBox.shrink();
                }
                final DateTime date = bars[index].date;
                final String label = range == StatsRange.week
                    ? DateFormat('EEE').format(date)
                    : DateFormat('d/M').format(date);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: <BarChartGroupData>[
          for (int i = 0; i < bars.length; i++)
            BarChartGroupData(
              x: i,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: bars[i].completed ? 1 : 0.06,
                  width: range == StatsRange.week ? 18 : 7,
                  color: bars[i].completed
                      ? color
                      : faint.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
