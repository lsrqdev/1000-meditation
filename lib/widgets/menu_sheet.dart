import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A bottom sheet menu with app settings and actions.
///
/// Provides controls for:
/// - Showing current program day
/// - Daily reminder notifications
/// - Sound and haptics toggles
/// - Parallax motion toggle
/// - About/Help
/// - Program reset
class MenuSheet extends StatelessWidget {
  /// Creates a menu sheet.
  const MenuSheet({
    super.key,
    required this.remindersEnabled,
    required this.reminderTime,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.parallaxEnabled,
    required this.onToggleReminders,
    required this.onPickReminderTime,
    required this.onToggleSound,
    required this.onToggleHaptics,
    required this.onToggleParallax,
    required this.onShowDay,
    required this.onShowAbout,
    required this.onResetProgram,
  });

  // State
  final bool remindersEnabled;
  final TimeOfDay reminderTime;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool parallaxEnabled;

  // Callbacks
  final ValueChanged<bool> onToggleReminders;
  final VoidCallback onPickReminderTime;
  final ValueChanged<bool> onToggleSound;
  final ValueChanged<bool> onToggleHaptics;
  final ValueChanged<bool> onToggleParallax;
  final VoidCallback onShowDay;
  final VoidCallback onShowAbout;
  final VoidCallback onResetProgram;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          // Header
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Show Day
          _MenuItem(
            icon: Icons.calendar_today_outlined,
            title: 'Show Day',
            onTap: onShowDay,
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Reminders
          _MenuSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Daily Reminders',
            subtitle: 'At ${_formatTime(reminderTime)}',
            value: remindersEnabled,
            onChanged: onToggleReminders,
            onTap: remindersEnabled
                ? onPickReminderTime
                : () => onToggleReminders(true),
          ),

          // Sound
          _MenuSwitchTile(
            icon: soundEnabled
                ? Icons.volume_up_outlined
                : Icons.volume_off_outlined,
            title: 'Sound',
            value: soundEnabled,
            onChanged: onToggleSound,
          ),

          // Haptics
          _MenuSwitchTile(
            icon: Icons.vibration_outlined,
            title: 'Haptics',
            value: hapticsEnabled,
            onChanged: onToggleHaptics,
          ),

          // Motion
          _MenuSwitchTile(
            icon: Icons.animation_outlined,
            title: 'Motion Effects',
            value: parallaxEnabled,
            onChanged: onToggleParallax,
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // About
          _MenuItem(
            icon: Icons.help_outline,
            title: 'About / Help',
            onTap: onShowAbout,
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Reset
          _MenuItem(
            icon: Icons.restart_alt,
            title: 'Reset Program',
            textColor: Colors.red.shade300,
            iconColor: Colors.red.shade300,
            onTap: onResetProgram,
          ),

          // Cancel
          _MenuItem(
            icon: Icons.close,
            title: 'Cancel',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: iconColor ?? Colors.white.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.white.withOpacity(0.9),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _MenuSwitchTile extends StatelessWidget {
  const _MenuSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.white.withOpacity(0.7)),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            )
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: onTap ?? (() => onChanged(!value)),
    );
  }
}
