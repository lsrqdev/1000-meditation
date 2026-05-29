import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onetoten_mobile/models/program_model.dart';
import 'package:onetoten_mobile/services/daily_completion_store.dart';
import 'package:onetoten_mobile/services/session_controller.dart';

void main() {
  group('SessionController', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late SharedPreferences prefs;
    late ProgramModel programModel;
    late DailyCompletionStore completionStore;
    SessionController? controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      programModel = ProgramModel(prefs);
      completionStore = DailyCompletionStore(prefs);
    });

    tearDown(() {
      controller?.dispose();
      controller = null;
    });

    group('initial state', () {
      test('is not running initially', () {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );
        expect(controller!.isRunning, false);
      });

      test('has no start date initially', () {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );
        expect(controller!.startDate, null);
      });

      test('has no end date initially', () {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );
        expect(controller!.endDate, null);
      });

      test('has zero progress initially', () {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );
        expect(controller!.progressToFinish, 0.0);
      });

      test('has zero remaining seconds initially', () {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );
        expect(controller!.remainingSeconds, 0.0);
      });
    });

    group('toggleSession - start', () {
      test('starts session when not running', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        // Skip haptic/audio for unit test
        controller!.toggleSession();

        // Allow async operations
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller!.isRunning, true);
      });

      test('sets target seconds based on program', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller!.targetSeconds, greaterThan(0));
      });

      test('does not start if already completed today', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        final today = DateTime.now();
        completionStore.setCompleted(true, today);

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller!.isRunning, false);
        expect(controller!.completedTodayNotice, true);
      });
    });

    group('toggleSession - stop', () {
      test('stops session when running', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));
        expect(controller!.isRunning, true);

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));
        expect(controller!.isRunning, false);
      });

      test('progress resets when stopped early', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));
        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller!.progressToFinish, 0.0);
      });
    });

    group('resetSessionState', () {
      test('resets all state', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));

        controller!.resetSessionState();

        expect(controller!.isRunning, false);
        expect(controller!.startDate, null);
        expect(controller!.endDate, null);
        expect(controller!.progressToFinish, 0.0);
        expect(controller!.remainingSeconds, 0.0);
      });

      test('clears completion pulse', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));
        controller!.resetSessionState();

        expect(controller!.completionPulse, 0.0);
        expect(controller!.completionHold, false);
      });
    });

    group('progress tracking', () {
      test('tracks progress between 0 and 1', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(controller!.progressToFinish, greaterThanOrEqualTo(0.0));
        expect(controller!.progressToFinish, lessThanOrEqualTo(1.0));
      });
    });

    group('notifications', () {
      test('notifies listeners on state change', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        var notified = false;
        controller!.addListener(() {
          notified = true;
        });

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notified, true);
      });
    });

    group('persistence', () {
      test('persists active session', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(prefs.getBool('sessionActive'), true);
        expect(prefs.getInt('sessionStart'), isNotNull);
        expect(prefs.getInt('sessionEnd'), isNotNull);
      });

      test('clears persistence on stop', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));
        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(prefs.getBool('sessionActive'), false);
      });

      test('restores session on creation if active', () async {
        // Start session
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));

        // Dispose without stopping (simulates app kill)
        controller!.dispose();
        controller = null;

        // Create new controller (simulating app restart)
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        expect(controller!.isRunning, true);
      });
    });

    group('lifecycle', () {
      test('safely handles dispose', () async {
        controller = SessionController(
          programModel: programModel,
          completionStore: completionStore,
          prefs: prefs,
        );

        controller!.toggleSession();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(() => controller!.dispose(), returnsNormally);

        // Don't use controller after dispose in tearDown
        controller = null;
      });
    });
  });
}
