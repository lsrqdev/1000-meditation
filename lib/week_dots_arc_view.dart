import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/program_model.dart';
import 'utils/date_helpers.dart';
import 'visual_spec.dart';

/// A widget that displays weekly progress dots arranged in an arc.
///
/// Shows completion status for the last 7 days, program milestone dots,
/// streak visualization, and the overall program progress indicator.
class WeekDotsArcView extends StatelessWidget {
  /// Creates a week dots arc view.
  const WeekDotsArcView({
    super.key,
    required this.last7Dates,
    required this.last7Completions,
    required this.focus,
    required this.today,
    required this.programProgress,
    required this.programDayIndex,
    required this.showProgramDay,
    required this.accentColor,
    this.milestonePulse = 0,
    this.isLuminanceReduced = false,
  });

  /// The last 7 dates to display (oldest to newest).
  final List<DateTime> last7Dates;

  /// Completion status for each of the last 7 dates.
  final List<bool> last7Completions;

  /// Focus value affecting opacity (0.0 to 1.0).
  /// Higher focus reduces dot opacity to emphasize the orb.
  final double focus;

  /// Today's date for highlighting.
  final DateTime today;

  /// Overall program progress (0.0 to 1.0).
  final double programProgress;

  /// Current day index in the program (1 to 1000).
  final int programDayIndex;

  /// Whether to show the "Day X" label.
  final bool showProgramDay;

  /// Accent color for completed days and milestones.
  final Color accentColor;

  /// Animation value for milestone pulse (0.0 to 1.0).
  final double milestonePulse;

  /// Whether to reduce luminance for accessibility.
  final bool isLuminanceReduced;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: VisualSpec.dotsOpacity(focus),
      child: CustomPaint(
        size: Size.infinite,
        painter: WeekDotsArcPainter(
          last7Dates: last7Dates,
          last7Completions: last7Completions,
          today: today,
          programProgress: programProgress,
          programDayIndex: programDayIndex,
          showProgramDay: showProgramDay,
          accentColor: accentColor,
          milestonePulse: milestonePulse,
          isLuminanceReduced: isLuminanceReduced,
        ),
      ),
    );
  }
}

/// Custom painter for the week dots arc visualization.
class WeekDotsArcPainter extends CustomPainter {
  /// Creates a week dots arc painter.
  WeekDotsArcPainter({
    required this.last7Dates,
    required this.last7Completions,
    required this.today,
    required this.programProgress,
    required this.programDayIndex,
    required this.showProgramDay,
    required this.accentColor,
    required this.milestonePulse,
    required this.isLuminanceReduced,
  });

  final List<DateTime> last7Dates;
  final List<bool> last7Completions;
  final DateTime today;
  final double programProgress;
  final int programDayIndex;
  final bool showProgramDay;
  final Color accentColor;
  final double milestonePulse;
  final bool isLuminanceReduced;

  @override
  void paint(Canvas canvas, Size size) {
    final orbDiameter = VisualSpec.orbDiameter(size.width, size.height);
    final orbCenter = VisualSpec.orbCenter(size.width, size.height);
    final arcRadius = VisualSpec.habitArcRadius(orbDiameter);
    final arcCenter = VisualSpec.habitArcCenter(orbCenter, orbDiameter);
    final dotSize = VisualSpec.dotDiameter(size.width);
    final ringLineWidth = VisualSpec.todayRingLineWidth(size.width);
    final arcLineWidth = VisualSpec.habitArcLineWidth(size.width);
    final startAngle = VisualSpec.deg2rad(VisualSpec.habitArcStartDeg);
    final endAngle = VisualSpec.deg2rad(VisualSpec.habitArcEndDeg);
    final step = (endAngle - startAngle) / math.max(last7Dates.length - 1, 1);
    final todayKey = DateHelpers.dayKey(today);
    final progress = programProgress.clamp(0.0, 1.0).toDouble();
    final milestoneStops = [
      0.0,
      ...ProgramModel.phaseDayCaps.map(
        (cap) => (cap - 1) / (ProgramModel.totalProgramDays - 1),
      ),
    ];
    var phaseIndex = 0;
    for (var index = 0; index < milestoneStops.length; index++) {
      if (progress >= milestoneStops[index]) {
        phaseIndex = index;
      } else {
        break;
      }
    }
    final milestoneRadius = arcRadius + dotSize * 0.9;
    final progressRadius = arcRadius + dotSize * 1.6;
    final pulse = milestonePulse.clamp(0.0, 1.0).toDouble();
    final pulseBoost = math.sin(pulse * math.pi);
    final milestoneActiveOpacity = isLuminanceReduced ? 0.58 : 0.72;
    final milestoneIdleOpacity = isLuminanceReduced ? 0.16 : 0.20;
    final progressOpacity = isLuminanceReduced ? 0.66 : 0.82;
    final guideOpacity = isLuminanceReduced ? 0.10 : 0.08;
    final streakOpacity = isLuminanceReduced ? 0.18 : 0.22;
    final dotIdleOpacity = isLuminanceReduced ? 0.28 : 0.22;
    final dotCompletedOpacity = isLuminanceReduced ? 0.74 : 0.84;
    final todayRingOpacity = isLuminanceReduced ? 0.74 : 0.88;
    final todayIdleOpacity = isLuminanceReduced ? 0.28 : 0.24;
    final programLabelOpacity = isLuminanceReduced ? 0.55 : 0.65;
    final programLabelSize = math.max(8.0, dotSize * 1.2);
    final programLabelRadius = arcRadius + dotSize * 2.8;
    final programLabelAngle = (startAngle + endAngle) * 0.5;

    final streakLength = _streakLength();

    // Draw guide arc
    _drawGuideArc(
      canvas,
      arcCenter,
      arcRadius,
      startAngle,
      endAngle,
      arcLineWidth,
      guideOpacity,
    );

    // Draw streak arc
    if (streakLength >= 3) {
      _drawStreakArc(
        canvas,
        arcCenter,
        arcRadius,
        startAngle,
        step,
        streakLength,
        last7Dates.length,
        arcLineWidth,
        streakOpacity,
      );
    }

    // Draw milestone dots
    _drawMilestoneDots(
      canvas,
      arcCenter,
      milestoneRadius,
      startAngle,
      endAngle,
      milestoneStops,
      phaseIndex,
      dotSize,
      pulseBoost,
      milestoneActiveOpacity,
      milestoneIdleOpacity,
    );

    // Draw progress indicator
    if (progress > 0) {
      _drawProgressIndicator(
        canvas,
        arcCenter,
        progressRadius,
        startAngle,
        endAngle,
        progress,
        dotSize,
        progressOpacity,
      );
    }

    // Draw day label
    if (showProgramDay) {
      _drawDayLabel(
        canvas,
        arcCenter,
        programLabelRadius,
        programLabelAngle,
        programLabelSize,
        programLabelOpacity,
      );
    }

    // Draw day dots
    _drawDayDots(
      canvas,
      arcCenter,
      arcRadius,
      startAngle,
      step,
      dotSize,
      ringLineWidth,
      todayKey,
      todayRingOpacity,
      todayIdleOpacity,
      dotCompletedOpacity,
      dotIdleOpacity,
    );
  }

  void _drawGuideArc(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double endAngle,
    double lineWidth,
    double opacity,
  ) {
    final guidePaint = Paint()
      ..color = VisualSpec.ink.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    final guidePath = Path();
    const samples = 36;
    for (var index = 0; index <= samples; index++) {
      final t = index / samples;
      final angle = startAngle + (endAngle - startAngle) * t;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy - math.sin(angle) * radius;
      if (index == 0) {
        guidePath.moveTo(x, y);
      } else {
        guidePath.lineTo(x, y);
      }
    }
    canvas.drawPath(guidePath, guidePaint);
  }

  void _drawStreakArc(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double step,
    int streakLength,
    int totalDays,
    double lineWidth,
    double opacity,
  ) {
    final streakStartIndex = math.max(totalDays - streakLength, 0);
    final streakEndIndex = totalDays - 1;
    final streakStartAngle = startAngle + step * streakStartIndex;
    final streakEndAngle = startAngle + step * streakEndIndex;
    final streakPath = Path();
    final streakSamples = math.max(10, streakLength * 6);
    for (var index = 0; index <= streakSamples; index++) {
      final t = index / streakSamples;
      final angle = streakStartAngle + (streakEndAngle - streakStartAngle) * t;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy - math.sin(angle) * radius;
      if (index == 0) {
        streakPath.moveTo(x, y);
      } else {
        streakPath.lineTo(x, y);
      }
    }
    final streakPaint = Paint()
      ..color = VisualSpec.ink.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth * 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(streakPath, streakPaint);
  }

  void _drawMilestoneDots(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double endAngle,
    List<double> stops,
    int activeIndex,
    double dotSize,
    double pulseBoost,
    double activeOpacity,
    double idleOpacity,
  ) {
    for (var index = 0; index < stops.length; index++) {
      final t = stops[index];
      final angle = startAngle + (endAngle - startAngle) * t;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy - math.sin(angle) * radius;
      final isActive = index == activeIndex;
      final size = dotSize * (isActive ? (0.45 + 0.1 * pulseBoost) : 0.3);

      final paint = Paint()
        ..color = VisualSpec.ink.withOpacity(
          isActive ? activeOpacity : idleOpacity,
        );
      canvas.drawCircle(Offset(x, y), size / 2, paint);
    }
  }

  void _drawProgressIndicator(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double endAngle,
    double progress,
    double dotSize,
    double opacity,
  ) {
    final progressAngle = startAngle + (endAngle - startAngle) * progress;
    final progressX = center.dx + math.cos(progressAngle) * radius;
    final progressY = center.dy - math.sin(progressAngle) * radius;
    final paint = Paint()
      ..color = VisualSpec.ink.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dotSize * 0.2;
    canvas.drawCircle(Offset(progressX, progressY), dotSize * 0.45, paint);
  }

  void _drawDayLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    double fontSize,
    double opacity,
  ) {
    final labelX = center.dx + math.cos(angle) * radius;
    final labelY = center.dy - math.sin(angle) * radius;
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Day $programDayIndex',
        style: TextStyle(
          color: VisualSpec.ink.withOpacity(opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
    );
  }

  void _drawDayDots(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double step,
    double dotSize,
    double ringLineWidth,
    String todayKey,
    double todayRingOpacity,
    double todayIdleOpacity,
    double completedOpacity,
    double idleOpacity,
  ) {
    for (var index = 0; index < last7Dates.length; index++) {
      final date = last7Dates[index];
      final angle = startAngle + step * index;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy - math.sin(angle) * radius;
      final isToday = DateHelpers.dayKey(date) == todayKey;
      final isCompleted = last7Completions[index];
      final todayRingSize = dotSize + 3.0;
      final todayRingWidth = ringLineWidth * 1.35;

      if (isToday) {
        final ringPaint = Paint()
          ..color = VisualSpec.ink.withOpacity(
            isCompleted ? todayRingOpacity : 0.65,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = todayRingWidth;
        canvas.drawCircle(Offset(x, y), todayRingSize / 2, ringPaint);
        if (isCompleted) {
          final dotPaint = Paint()
            ..color = VisualSpec.ink.withOpacity(0.92)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
          canvas.drawCircle(Offset(x, y), dotSize / 2, dotPaint);
        } else {
          final dotPaint = Paint()
            ..color = VisualSpec.ink.withOpacity(todayIdleOpacity);
          canvas.drawCircle(Offset(x, y), dotSize / 2, dotPaint);
        }
      } else {
        final dotPaint = Paint()
          ..color = VisualSpec.ink.withOpacity(
            isCompleted ? completedOpacity : idleOpacity,
          );
        canvas.drawCircle(Offset(x, y), dotSize / 2, dotPaint);
      }
    }
  }

  int _streakLength() {
    var count = 0;
    for (var index = last7Completions.length - 1; index >= 0; index--) {
      if (last7Completions[index]) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  @override
  bool shouldRepaint(covariant WeekDotsArcPainter oldDelegate) {
    return !_sameDay(oldDelegate.today, today) ||
        !_sameDates(oldDelegate.last7Dates, last7Dates) ||
        !_sameCompletions(oldDelegate.last7Completions, last7Completions) ||
        oldDelegate.programProgress != programProgress ||
        oldDelegate.programDayIndex != programDayIndex ||
        oldDelegate.showProgramDay != showProgramDay ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.milestonePulse != milestonePulse ||
        oldDelegate.isLuminanceReduced != isLuminanceReduced;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _sameDates(List<DateTime> a, List<DateTime> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (!_sameDay(a[index], b[index])) return false;
    }
    return true;
  }

  bool _sameCompletions(List<bool> a, List<bool> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
