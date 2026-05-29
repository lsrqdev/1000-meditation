import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/program_model.dart';
import '../services/daily_completion_store.dart';
import '../utils/date_helpers.dart';
import '../visual_spec.dart';

/// A screen displaying detailed meditation statistics.
///
/// Shows historical data including:
/// - Total days completed and progress
/// - Current and longest streak
/// - Total minutes meditated
/// - Weekly and monthly completion rates
/// - Phase progress
class StatisticsScreen extends StatefulWidget {
  /// Creates a statistics screen.
  const StatisticsScreen({
    super.key,
    required this.programModel,
    required this.completionStore,
  });

  /// The program model for accessing program data.
  final ProgramModel programModel;

  /// The completion store for accessing completion records.
  final DailyCompletionStore completionStore;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Map<String, dynamic> _stats;

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  void _calculateStats() {
    final today = DateTime.now();
    final startDate = widget.programModel.programStartDate;
    final completedDates = widget.completionStore.getAllCompletedDates();
    final completedSet = Set<String>.from(completedDates);

    // Basic counts
    final totalDays = widget.programModel.dayIndexSinceStart(today);
    final daysCompleted = completedDates.length;

    // Streaks
    final currentStreak = widget.completionStore.getStreakLength(today);
    final longestStreak = _calculateLongestStreak(
      completedSet,
      startDate,
      today,
    );

    // Minutes
    var totalMinutes = 0;
    for (final dateKey in completedDates) {
      final date = DateTime.parse(dateKey);
      final dayIndex = widget.programModel.dayIndexSinceStart(date);
      totalMinutes += widget.programModel.targetMinutesForDay(dayIndex);
    }

    // Weekly stats (last 4 weeks)
    final weeklyStats = _calculateWeeklyStats(today, completedSet);

    // Phase progress
    final currentPhase = widget.programModel.currentPhaseIndex(today);
    final phaseProgress = widget.programModel.phaseProgress(today);
    final phaseDays = widget.programModel.daysIntoPhase(today);
    final phaseTotalDays = widget.programModel.totalDaysInPhase(today);

    setState(() {
      _stats = {
        'totalDays': totalDays,
        'daysCompleted': daysCompleted,
        'completionRate': totalDays > 0 ? daysCompleted / totalDays : 0.0,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalMinutes': totalMinutes,
        'weeklyStats': weeklyStats,
        'currentPhase': currentPhase + 1,
        'phaseProgress': phaseProgress,
        'phaseDays': phaseDays,
        'phaseTotalDays': phaseTotalDays,
        'programProgress': widget.programModel.programProgress(today),
      };
    });
  }

  int _calculateLongestStreak(
    Set<String> completedSet,
    DateTime startDate,
    DateTime endDate,
  ) {
    var longest = 0;
    var current = 0;
    var checkDate = endDate;

    // Count backwards from today
    while (!checkDate.isBefore(startDate)) {
      final key = DateHelpers.dayKey(checkDate);
      if (completedSet.contains(key)) {
        current++;
        longest = current > longest ? current : longest;
      } else {
        current = 0;
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return longest;
  }

  List<Map<String, dynamic>> _calculateWeeklyStats(
    DateTime today,
    Set<String> completedSet,
  ) {
    final stats = <Map<String, dynamic>>[];

    for (var week = 0; week < 4; week++) {
      final weekEnd = today.subtract(Duration(days: week * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));

      var completed = 0;
      var checkDate = weekEnd;
      while (!checkDate.isBefore(weekStart)) {
        if (completedSet.contains(DateHelpers.dayKey(checkDate))) {
          completed++;
        }
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      stats.add({
        'week': week == 0 ? 'This week' : '${week * 7} days ago',
        'completed': completed,
        'total': 7,
      });
    }

    return stats;
  }

  Future<void> _exportData() async {
    final today = DateTime.now();
    final completedDates = widget.completionStore.getAllCompletedDates();

    final exportData = {
      'exportVersion': 1,
      'exportDate': DateHelpers.dayKey(today),
      'programStartDate': DateHelpers.dayKey(
        widget.programModel.programStartDate,
      ),
      'totalDaysCompleted': completedDates.length,
      'completions': completedDates..sort(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/1000_backup.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([XFile(file.path)], subject: '1000 Backup');
    } else {
      await Clipboard.setData(ClipboardData(text: jsonString));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data copied to clipboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = VisualSpec.phaseAccent(
      _stats['currentPhase'] != null ? (_stats['currentPhase'] as int) - 1 : 0,
    );

    return Scaffold(
      backgroundColor: VisualSpec.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: VisualSpec.ink,
        title: Text(
          'Statistics',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            fontWeight: FontWeight.w300,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportData,
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress overview
              _buildProgressCard(accentColor),
              const SizedBox(height: 24),

              // Streaks
              _buildStreaksCard(accentColor),
              const SizedBox(height: 24),

              // Time stats
              _buildTimeCard(),
              const SizedBox(height: 24),

              // Phase progress
              _buildPhaseCard(accentColor),
              const SizedBox(height: 24),

              // Weekly stats
              _buildWeeklyStatsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(Color accentColor) {
    final totalDays = _stats['totalDays'] as int? ?? 0;
    final daysCompleted = _stats['daysCompleted'] as int? ?? 0;
    final completionRate = (_stats['completionRate'] as double? ?? 0) * 100;
    final programProgress = (_stats['programProgress'] as double? ?? 0) * 100;

    return _buildCard(
      title: 'Progress',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('$daysCompleted', 'Days Done', accentColor),
              _buildStatColumn(
                '$totalDays',
                'Total Days',
                VisualSpec.ink.withOpacity(0.72),
              ),
              _buildStatColumn(
                '${completionRate.toStringAsFixed(0)}%',
                'Success Rate',
                accentColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: programProgress / 100,
              backgroundColor: VisualSpec.ink.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${programProgress.toStringAsFixed(1)}% of 1000 days',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: VisualSpec.ink.withOpacity(0.54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksCard(Color accentColor) {
    final currentStreak = _stats['currentStreak'] as int? ?? 0;
    final longestStreak = _stats['longestStreak'] as int? ?? 0;

    return _buildCard(
      title: 'Streaks',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            '$currentStreak',
            currentStreak == 1 ? 'Day Current' : 'Days Current',
            accentColor,
          ),
          Container(width: 1, height: 40, color: VisualSpec.hairWithOpacity()),
          _buildStatColumn(
            '$longestStreak',
            longestStreak == 1 ? 'Day Best' : 'Days Best',
            VisualSpec.ink.withOpacity(0.72),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    final totalMinutes = _stats['totalMinutes'] as int? ?? 0;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return _buildCard(
      title: 'Time Meditated',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatColumn(
            '$hours',
            hours == 1 ? 'Hour' : 'Hours',
            VisualSpec.ink,
          ),
          const SizedBox(width: 24),
          _buildStatColumn(
            '$minutes',
            minutes == 1 ? 'Minute' : 'Minutes',
            VisualSpec.ink.withOpacity(0.72),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(Color accentColor) {
    final currentPhase = _stats['currentPhase'] as int? ?? 1;
    final phaseProgress = _stats['phaseProgress'] as double? ?? 0.0;
    final phaseDays = _stats['phaseDays'] as int? ?? 0;
    final phaseTotalDays = _stats['phaseTotalDays'] as int? ?? 0;

    return _buildCard(
      title: 'Phase $currentPhase',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day $phaseDays of $phaseTotalDays',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: VisualSpec.ink.withOpacity(0.72),
                ),
              ),
              Text(
                '${(phaseProgress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: phaseProgress,
              backgroundColor: VisualSpec.ink.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsCard() {
    final weeklyStats =
        _stats['weeklyStats'] as List<Map<String, dynamic>>? ?? [];

    return _buildCard(
      title: 'Last 4 Weeks',
      child: Column(
        children: weeklyStats.map((week) {
          final completed = week['completed'] as int;
          final total = week['total'] as int;
          final progress = completed / total;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    week['week'] as String,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: VisualSpec.ink.withOpacity(0.54),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: VisualSpec.ink.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        VisualSpec.ink.withOpacity(0.72),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completed/$total',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: VisualSpec.ink.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VisualSpec.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VisualSpec.hairWithOpacity()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: VisualSpec.ink.withOpacity(0.86),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: VisualSpec.ink.withOpacity(0.54),
          ),
        ),
      ],
    );
  }
}
