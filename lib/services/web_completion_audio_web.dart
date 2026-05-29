import 'dart:js_util' as js_util;

class WebCompletionAudio {
  static Object? get _audio =>
      js_util.getProperty(js_util.globalThis, 'meditationAudio');

  static Future<bool> unlock() async {
    final audio = _audio;
    if (audio == null) return false;

    try {
      final result = js_util.callMethod<Object?>(audio, 'unlock', const []);
      if (result == null) return false;
      return await js_util.promiseToFuture<bool>(result);
    } catch (_) {
      return false;
    }
  }

  static bool startSessionAudio() {
    final audio = _audio;
    if (audio == null) return false;

    try {
      return js_util.callMethod<bool>(audio, 'startSessionAudio', const []);
    } catch (_) {
      return false;
    }
  }

  static bool stopSessionAudio() {
    final audio = _audio;
    if (audio == null) return false;

    try {
      return js_util.callMethod<bool>(audio, 'stopSessionAudio', const []);
    } catch (_) {
      return false;
    }
  }

  static bool requestWakeLock() {
    final audio = _audio;
    if (audio == null) return false;

    try {
      js_util.callMethod<Object?>(audio, 'requestWakeLock', const []);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool releaseWakeLock() {
    final audio = _audio;
    if (audio == null) return false;

    try {
      return js_util.callMethod<bool>(audio, 'releaseWakeLock', const []);
    } catch (_) {
      return false;
    }
  }

  static bool playBell() {
    final audio = _audio;
    if (audio == null) return false;

    try {
      return js_util.callMethod<bool>(audio, 'playBell', const []);
    } catch (_) {
      return false;
    }
  }
}
