# 1000 - AI Agent Guide

## Project Overview

**1000** is a Flutter-based mobile application for meditation practice. The app guides users through a 1000-day progressive meditation program, gradually building from 3 minutes to 30 minutes of daily practice.

### Key Features
- **Progressive Program**: 9 phases over 1000 days (3→5→7→10→12→15→20→25→30 minutes)
- **Session Timer**: Visual countdown timer with animated orb interface
- **Streak Tracking**: Weekly progress and consecutive day streaks
- **Daily Reminders**: Configurable push notifications
- **Parallax Motion**: Interactive 3D-like orb effect (can be disabled for accessibility)
- **Phase Milestones**: Celebratory badges when unlocking new phases
- **Persistent Storage**: All progress saved locally via SharedPreferences

## Technology Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter SDK ^3.10.7 |
| Language | Dart |
| State Management | `ChangeNotifier` + `AnimatedBuilder` |
| Local Storage | `shared_preferences` |
| Notifications | `flutter_local_notifications` + `timezone` |
| Fonts | `google_fonts` (Manrope, Cormorant Garamond) |
| Icons | `cupertino_icons` |

### Supported Platforms
- iOS
- Android
- macOS
- Windows
- Linux
- Web

## Project Structure

```
lib/
├── main.dart                    # App entry point, theme config
├── one_surface_view.dart        # Main UI screen (~1077 lines)
├── orb_view.dart                # Animated meditation orb widget
├── week_dots_arc_view.dart      # Weekly progress arc visualization
├── program_model.dart           # 1000-day program logic
├── session_controller.dart      # Timer state management
├── daily_completion_store.dart  # Daily completion persistence
├── settings_store.dart          # User preferences storage
├── notifications_service.dart   # Push notification handling
├── visual_spec.dart             # Design constants & calculations
└── date_helpers.dart            # Date utility functions
```

## Architecture

### State Management Pattern
The app uses Flutter's built-in state management:

- **`SessionController`** (`ChangeNotifier`): Manages timer state, session lifecycle, and completion tracking
- **`ProgramModel`**: Pure logic class for calculating daily targets and program progress
- **`SettingsStore`**: Simple wrapper around SharedPreferences for user settings
- **`DailyCompletionStore`**: Handles persistence of daily completion records

### Key Controllers & Models

```dart
// SessionController lifecycle
SessionController
  ├── toggleSession()           // Start/stop meditation session
  ├── _startSession()           // Initialize timer, calculate end time
  ├── _stopSession()            // Check completion, mark done
  ├── _tick()                   // Update progress every 500ms
  └── _restoreSessionIfNeeded() // Recover active session on app restart
```

```dart
// ProgramModel phases
Phase 1: Days 1-30    → 3 minutes
Phase 2: Days 31-90   → 5 minutes
Phase 3: Days 91-180  → 7 minutes
Phase 4: Days 181-300 → 10 minutes
Phase 5: Days 301-450 → 12 minutes
Phase 6: Days 451-650 → 15 minutes
Phase 7: Days 651-800 → 20 minutes
Phase 8: Days 801-900 → 25 minutes
Phase 9: Days 901-1000 → 30 minutes
```

## Build Commands

```bash
# Get dependencies
flutter pub get

# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device_id>

# Build for production
flutter build apk              # Android
flutter build ios              # iOS
flutter build web              # Web
flutter build macos            # macOS
flutter build windows          # Windows
flutter build linux            # Linux

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

## Testing

The project has minimal test coverage with a single widget test:

```bash
flutter test
```

### Test Structure
- `test/widget_test.dart`: Basic widget test verifying onboarding screen appears on first launch

### Testing Notes
- Uses `SharedPreferences.setMockInitialValues({})` to mock storage in tests
- Test verifies onboarding text appears when `hasSeenOnboarding` is false

## Code Style Guidelines

### Dart/Flutter Conventions
- Follows `flutter_lints` ruleset (standard Flutter linting)
- Uses `snake_case` for file names
- Uses `PascalCase` for class names
- Uses `camelCase` for methods and variables
- Private members prefixed with underscore (`_`)

### UI Patterns
- Uses `LayoutBuilder` for responsive sizing calculations
- Custom `CustomPainter` classes for complex visualizations (orb, progress rings, film grain)
- `AnimatedBuilder` and `AnimationController` for smooth animations
- Accessibility support via `MediaQuery.accessibleNavigation` and `highContrast` checks

### Key Naming Conventions
- `VisualSpec.*` - Design system constants and calculations
- `*Store` - Data persistence classes
- `*Controller` - State management classes
- `*Painter` - CustomPaint implementations

## Development Conventions

### Adding New Features
1. **UI Components**: Create new widget files in `lib/`
2. **Storage**: Add keys to appropriate `*Store` class
3. **Notifications**: Modify `NotificationsService` for notification features
4. **Visual Design**: Update `VisualSpec` for design system changes

### State Changes
Always use the controller pattern:
```dart
// Good
sessionController.toggleSession();  // Notifies listeners internally

// In UI
ListenableBuilder(
  listenable: sessionController,
  builder: (context, _) => // rebuild
)
```

### Date Handling
Always use `DateHelpers` for date operations:
```dart
// Good
final key = DateHelpers.dayKey(date);
final start = DateHelpers.startOfLocalDay(date);

// Bad - don't manually format dates
final key = "${date.year}-${date.month}-${date.day}";
```

## Security Considerations

- **Local Storage Only**: All data stored via `SharedPreferences` (unencrypted local storage)
- **No Network Calls**: App is completely offline, no API keys or network security concerns
- **Notification Permissions**: App requests notification permissions at runtime
- **Android Permission**: `POST_NOTIFICATIONS` declared in `AndroidManifest.xml`

## Configuration Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Dependencies, Flutter config, assets |
| `analysis_options.yaml` | Dart analyzer rules (uses `flutter_lints`) |
| `android/app/src/main/AndroidManifest.xml` | Android permissions and config |
| `ios/Runner/Info.plist` | iOS bundle configuration |

## Dependencies

### Production
```yaml
shared_preferences: ^2.3.2        # Local storage
flutter_local_notifications: ^17.1.2  # Push notifications
timezone: ^0.9.4                  # Timezone handling
flutter_timezone: ^1.0.8          # Device timezone
google_fonts: ^6.2.1              # Typography
cupertino_icons: ^1.0.8           # iOS-style icons
```

### Development
```yaml
flutter_test: (sdk)               # Testing framework
flutter_lints: ^6.0.0             # Lint rules
```

## Platform-Specific Notes

### iOS
- Supports Portrait and Landscape orientations (iPhone)
- Supports all orientations on iPad
- Notifications require user permission at runtime

### Android
- Requires `POST_NOTIFICATIONS` permission for reminders
- Uses `@mipmap/ic_launcher` for notification icon

### Web
- Notifications service initializes but doesn't schedule (web limitation)
- Parallax effects work with mouse hover

## Accessibility

The app includes accessibility considerations:
- **Reduce Motion**: Respects `MediaQuery.accessibleNavigation`
- **High Contrast**: Adjusts opacity when `MediaQuery.highContrast` is enabled
- **Parallax Toggle**: Users can disable motion effects in settings menu
- **Haptic/Sound Toggle**: Can disable feedback cues

## Common Tasks

### Add a New Program Phase
1. Update `phaseDayCaps` and `phaseMinutes` in `ProgramModel`
2. Add corresponding accent color in `VisualSpec.phaseAccents`

### Modify Notification Content
Edit `NotificationsService._dailyReminderId` and notification strings in `scheduleDailyReminder()`

### Change Visual Theme
Modify `VisualSpec.phaseAccents` for color progression and `VisualSpec` constants for sizing

### Add New Settings
1. Add key constant in `SettingsStore`
2. Add getter/setter pair
3. Add UI control in `OneSurfaceView._openMenu()`
