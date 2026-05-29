import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onetoten_mobile/services/settings_store.dart';

void main() {
  group('SettingsStore', () {
    late SharedPreferences prefs;
    late SettingsStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = SettingsStore(prefs);
    });

    group('parallaxEnabled', () {
      test('defaults to false', () {
        expect(store.parallaxEnabled, false);
      });

      test('can be set and retrieved', () {
        store.parallaxEnabled = true;
        expect(store.parallaxEnabled, true);

        store.parallaxEnabled = false;
        expect(store.parallaxEnabled, false);
      });
    });

    group('hasSeenOnboarding', () {
      test('defaults to false', () {
        expect(store.hasSeenOnboarding, false);
      });

      test('can be set and retrieved', () {
        store.hasSeenOnboarding = true;
        expect(store.hasSeenOnboarding, true);
      });
    });

    group('hasOpenedMenu', () {
      test('defaults to false', () {
        expect(store.hasOpenedMenu, false);
      });

      test('can be set and retrieved', () {
        store.hasOpenedMenu = true;
        expect(store.hasOpenedMenu, true);
      });
    });

    group('remindersEnabled', () {
      test('defaults to false', () {
        expect(store.remindersEnabled, false);
      });

      test('can be set and retrieved', () {
        store.remindersEnabled = true;
        expect(store.remindersEnabled, true);
      });
    });

    group('reminderTimeMinutes', () {
      test('defaults to 480 (8:00 AM)', () {
        expect(store.reminderTimeMinutes, 480);
      });

      test('can be set and retrieved', () {
        store.reminderTimeMinutes = 900; // 3:00 PM
        expect(store.reminderTimeMinutes, 900);
      });
    });

    group('lastReminderDay', () {
      test('defaults to null', () {
        expect(store.lastReminderDay, null);
      });

      test('can be set and retrieved', () {
        store.lastReminderDay = '2026-03-15';
        expect(store.lastReminderDay, '2026-03-15');
      });

      test('can be set to null', () {
        store.lastReminderDay = '2026-03-15';
        store.lastReminderDay = null;
        expect(store.lastReminderDay, null);
      });
    });

    group('soundEnabled', () {
      test('defaults to true', () {
        expect(store.soundEnabled, true);
      });

      test('can be disabled', () {
        store.soundEnabled = false;
        expect(store.soundEnabled, false);
      });
    });

    group('hapticsEnabled', () {
      test('defaults to true', () {
        expect(store.hapticsEnabled, true);
      });

      test('can be disabled', () {
        store.hapticsEnabled = false;
        expect(store.hapticsEnabled, false);
      });
    });

    group('lastPhaseBadgeDay', () {
      test('defaults to null', () {
        expect(store.lastPhaseBadgeDay, null);
      });

      test('can be set and retrieved', () {
        store.lastPhaseBadgeDay = 30;
        expect(store.lastPhaseBadgeDay, 30);
      });

      test('can be set to null', () {
        store.lastPhaseBadgeDay = 30;
        store.lastPhaseBadgeDay = null;
        expect(store.lastPhaseBadgeDay, null);
      });
    });

    group('restDaysEnabled', () {
      test('defaults to true', () {
        expect(store.restDaysEnabled, true);
      });

      test('can be disabled', () {
        store.restDaysEnabled = false;
        expect(store.restDaysEnabled, false);
      });
    });

    group('freezeStreaks', () {
      test('defaults to 3 available', () {
        expect(store.freezeStreaksAvailable, 3);
      });

      test('defaults to 0 used', () {
        expect(store.freezeStreaksUsed, 0);
      });

      test('calculates remaining correctly', () {
        expect(store.freezeStreaksRemaining, 3);

        store.freezeStreaksUsed = 1;
        expect(store.freezeStreaksRemaining, 2);

        store.freezeStreaksUsed = 3;
        expect(store.freezeStreaksRemaining, 0);
      });

      test('tracks usage', () {
        store.freezeStreaksUsed = 2;
        expect(store.freezeStreaksUsed, 2);
        expect(store.freezeStreaksRemaining, 1);
      });
    });

    group('selectedSoundscape', () {
      test('defaults to silence', () {
        expect(store.selectedSoundscape, 'silence');
      });

      test('can be changed', () {
        store.selectedSoundscape = 'rain';
        expect(store.selectedSoundscape, 'rain');
      });
    });

    group('persistence', () {
      test('values persist across store instances', () {
        store.parallaxEnabled = true;
        store.soundEnabled = false;
        store.reminderTimeMinutes = 600;
        store.restDaysEnabled = false;
        store.freezeStreaksUsed = 2;
        store.selectedSoundscape = 'ocean';

        final newStore = SettingsStore(prefs);
        expect(newStore.parallaxEnabled, true);
        expect(newStore.soundEnabled, false);
        expect(newStore.reminderTimeMinutes, 600);
        expect(newStore.restDaysEnabled, false);
        expect(newStore.freezeStreaksUsed, 2);
        expect(newStore.selectedSoundscape, 'ocean');
      });
    });
  });
}
