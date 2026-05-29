import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_screen.dart';
import 'services/notifications_service.dart';

/// The entry point for the 1000 app.
///
/// Initializes Flutter bindings, SharedPreferences, and notifications
/// before running the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only on phones)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  await NotificationsService.instance.initialize();

  runApp(ThousandApp(prefs: prefs));
}

/// The root widget of the 1000 application.
///
/// Configures the app theme, fonts, and initial route.
class ThousandApp extends StatelessWidget {
  /// Creates the app with the given preferences.
  const ThousandApp({super.key, required this.prefs});

  /// Shared preferences instance for persistence.
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1000',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        textTheme: GoogleFonts.manropeTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF76C5C8),
          brightness: Brightness.dark,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF101010),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF101010),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
      ),
      home: MainScreen(prefs: prefs),
    );
  }
}
