import 'dart:math';

import 'package:flutter/material.dart';

/// Design system constants and calculations for the 1000 app.
///
/// Contains all visual specifications including colors, sizing functions,
/// and animation parameters. All sizes are responsive and scale with
/// screen dimensions.
class VisualSpec {
  VisualSpec._(); // Prevent instantiation

  // Animation
  /// Period of the levitation animation in seconds.
  static const double levitationPeriod = 8.0;

  // Arc geometry (degrees)
  /// Start angle of the weekly progress arc.
  static const double habitArcStartDeg = 200;

  /// End angle of the weekly progress arc.
  static const double habitArcEndDeg = 340;

  // Phase accent colors
  /// Accent colors for each of the 9 program phases.
  static const List<Color> phaseAccents = [
    Color(0xFF76C5C8), // Phase 1: Soft teal
    Color(0xFF6AB8D6), // Phase 2: Sky blue
    Color(0xFF78C2A1), // Phase 3: Mint green
    Color(0xFF8FC16C), // Phase 4: Lime green
    Color(0xFFC0B566), // Phase 5: Olive gold
    Color(0xFFD1A86B), // Phase 6: Golden
    Color(0xFFD89A69), // Phase 7: Orange
    Color(0xFFDE8B64), // Phase 8: Coral
    Color(0xFFE07E5F), // Phase 9: Salmon
  ];

  // Sizing functions

  /// Calculates the orb diameter based on screen dimensions.
  ///
  /// The orb takes up 68% of the smaller screen dimension.
  static double orbDiameter(double width, double height) {
    return 0.68 * min(width, height);
  }

  /// Calculates the orb center position.
  ///
  /// Centered horizontally, positioned at 46% of screen height.
  static Offset orbCenter(double width, double height) {
    return Offset(0.5 * width, 0.46 * height);
  }

  /// Calculates the habit arc radius based on orb diameter.
  static double habitArcRadius(double orbDiameter) {
    return 0.62 * orbDiameter;
  }

  /// Calculates the habit arc center (same as orb center).
  static Offset habitArcCenter(Offset orbCenter, double orbDiameter) {
    return orbCenter;
  }

  /// Calculates the dot diameter based on screen width.
  static double dotDiameter(double width) {
    return clamp(5.0, 0.015 * width, 6.0);
  }

  /// Calculates the today ring line width.
  static double todayRingLineWidth(double width) {
    return clamp(1.4, 0.004 * width, 1.9);
  }

  /// Calculates the habit arc line width.
  static double habitArcLineWidth(double width) {
    return clamp(0.6, 0.0035 * width, 1.1);
  }

  /// Calculates the numeral font size in idle state.
  static double idleNumeralSize(double width) {
    return clamp(24.0, 0.080 * width, 30.0);
  }

  /// Calculates the numeral font size during a session.
  static double runningNumeralSize(double width) {
    return clamp(26.0, 0.088 * width, 32.0);
  }

  /// Calculates the progress ring diameter.
  static double progressRingDiameter(double orbDiameter) {
    return orbDiameter * 1.14;
  }

  /// Calculates the progress ring line width.
  static double progressRingLineWidth(double orbDiameter) {
    return clamp(1.2, 0.015 * orbDiameter, 2.4);
  }

  /// Calculates the levitation amplitude based on screen height.
  static double levitationAmplitude(double height) {
    return clamp(2.0, 0.012 * height, 5.0);
  }

  /// Calculates the parallax amplitude based on screen dimensions.
  static double parallaxAmplitude(double width, double height) {
    return clamp(2.0, 0.012 * min(width, height), 6.0);
  }

  // Opacity calculations

  /// Calculates the dots opacity based on focus level.
  ///
  /// Dots fade out as focus increases (user starts session).
  static double dotsOpacity(double focus) {
    final t = clamp(0.0, focus, 1.0);
    final curve = pow(1.0 - t, 2.0).toDouble();
    return 0.25 + curve * 0.75;
  }

  /// Calculates the background opacity based on focus level.
  ///
  /// Background fades as focus increases.
  static double backgroundOpacity(double focus) {
    final t = clamp(0.0, focus, 1.0);
    final curve = pow(1.0 - t, 3.0).toDouble();
    return 0.3 + curve * 0.7;
  }

  /// Calculates the orb core boost (scale) based on focus level.
  static double orbCoreBoost(double focus) {
    return 1.0 + 0.06 * clamp(0.0, focus, 1.0);
  }

  /// Returns the accent color for a given phase.
  ///
  /// If [isLuminanceReduced] is true, returns a dimmed version.
  static Color phaseAccent(int phaseIndex, {bool isLuminanceReduced = false}) {
    final safeIndex = phaseIndex.clamp(0, phaseAccents.length - 1);
    final base = phaseAccents[safeIndex];
    return isLuminanceReduced ? base.withOpacity(0.6) : base;
  }

  // Utility functions

  /// Clamps a value between min and max.
  static double clamp(double minValue, double value, double maxValue) {
    return max(minValue, min(value, maxValue));
  }

  /// Converts degrees to radians.
  static double deg2rad(double deg) {
    return deg * pi / 180.0;
  }
}
