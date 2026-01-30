import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dashboard'da kullanılabilecek grafik türleri.
enum DashboardChartType {
  bar('Dikey çubuk'),
  horizontalBar('Yatay çubuk'),
  pie('Pasta'),
  donut('Halka'),
  timeSeries('Zaman (bitişe göre)');

  const DashboardChartType(this.label);
  final String label;
}

List<Color> _chartPalette(ThemeData t) => [
      t.colorScheme.primary,
      t.colorScheme.secondary,
      t.colorScheme.tertiary,
      t.colorScheme.error,
      t.colorScheme.primaryContainer,
      t.colorScheme.secondaryContainer,
      t.colorScheme.tertiaryContainer,
    ];

/// Dikey çubuk grafik.
class BarChart extends StatelessWidget {
  final Map<String, int> data;
  final Color color;

  const BarChart({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final ratio = maxVal > 0 ? (e.value / maxVal) : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 120 * ratio,
                        width: 16,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.key,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${e.value}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Yatay çubuk grafik: etiket solda, çubuk sağa doğru.
class HorizontalBarChart extends StatelessWidget {
  final Map<String, int> data;
  final Color color;

  const HorizontalBarChart({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) return const SizedBox.shrink();
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 56.0 * entries.length.clamp(1, 8),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          final ratio = maxVal > 0 ? (e.value / maxVal) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    e.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${e.value}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// widthFactor ile genişlik veren wrapper.
class FractionallySizedBox extends StatelessWidget {
  final double widthFactor;
  final Widget child;

  const FractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth * widthFactor.clamp(0.0, 1.0)).clamp(0.0, double.infinity);
        return SizedBox(width: w, child: child);
      },
    );
  }
}

/// Pasta grafik (CustomPainter).
class PieChart extends StatelessWidget {
  final Map<String, int> data;
  final ThemeData theme;

  const PieChart({super.key, required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final entries = data.entries.toList();
    final colors = _chartPalette(theme);
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _PiePainter(
                data: entries.map((e) => e.value / total).toList(),
                colors: List.generate(entries.length, (i) => colors[i % colors.length]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${e.key} (${e.value})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;

  _PiePainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.85;
    var start = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweep = 2 * math.pi * data[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Halka (donut) grafik.
class DonutChart extends StatelessWidget {
  final Map<String, int> data;
  final ThemeData theme;

  const DonutChart({super.key, required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final entries = data.entries.toList();
    final colors = _chartPalette(theme);
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _DonutPainter(
                data: entries.map((e) => e.value / total).toList(),
                colors: List.generate(entries.length, (i) => colors[i % colors.length]),
                holeColor: theme.colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${e.key} (${e.value})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;
  final Color holeColor;

  _DonutPainter({required this.data, required this.colors, required this.holeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.85;
    const holeRatio = 0.5;
    var start = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweep = 2 * math.pi * data[i];
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, sweep, true, Paint()..color = colors[i]);
      start += sweep;
    }
    canvas.drawCircle(
      center,
      radius * holeRatio,
      Paint()..color = holeColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Zaman serisi: tarih (gün) -> sayı. X: günler, Y: iş sayısı.
class TimeSeriesChart extends StatelessWidget {
  final Map<String, int> data;
  final Color color;

  const TimeSeriesChart({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) return const SizedBox.shrink();
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxVal = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final ratio = maxVal > 0 ? (e.value / maxVal) : 0.0;
          final label = e.key.length >= 10 ? e.key.substring(8, 10) : e.key;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 100 * ratio,
                        width: 12,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    '${e.value}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
