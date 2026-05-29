import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import 'web_completion_audio.dart';

/// Manages ambient soundscapes for meditation sessions.
///
/// Provides various ambient sounds that can play during meditation:
/// - Silence (default)
/// - Rain
/// - Ocean
/// - Forest
/// - White noise
/// - Plus a completion bell sound
class SoundscapeService {
  SoundscapeService._();

  /// The singleton instance.
  static final SoundscapeService instance = SoundscapeService._();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  String _currentSoundscape = 'silence';
  bool _isInitialized = false;

  /// Available soundscapes with their display names.
  static const Map<String, String> soundscapes = {
    'silence': 'Silence',
    'rain': 'Rain',
    'ocean': 'Ocean Waves',
    'forest': 'Forest',
    'whitenoise': 'White Noise',
    'pinknoise': 'Pink Noise',
  };

  /// Asset paths for soundscapes.
  static const Map<String, String?> soundscapeAssets = {
    'silence': null,
    'rain': 'assets/audio/rain.mp3',
    'ocean': 'assets/audio/ocean.mp3',
    'forest': 'assets/audio/forest.mp3',
    'whitenoise': 'assets/audio/whitenoise.mp3',
    'pinknoise': 'assets/audio/pinknoise.mp3',
  };

  /// Path to the completion bell sound.
  static const String bellAsset = 'assets/audio/bell.mp3';

  /// Gets the currently selected soundscape.
  String get currentSoundscape => _currentSoundscape;

  /// Whether the service is initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the audio session.
  ///
  /// Should be called before playing any audio.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidWillPauseWhenDucked: false,
        ),
      );

      // Set up looping for main player
      await _player.setLoopMode(LoopMode.one);

      _isInitialized = true;
      developer.log(
        'Soundscape service initialized',
        name: 'SoundscapeService',
      );
    } catch (e) {
      developer.log(
        'Error initializing soundscape service: $e',
        name: 'SoundscapeService',
      );
    }
  }

  /// Sets the current soundscape by ID.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> setSoundscape(String soundscapeId) async {
    await initialize();

    if (!soundscapes.containsKey(soundscapeId)) {
      developer.log(
        'Invalid soundscape: $soundscapeId',
        name: 'SoundscapeService',
      );
      return false;
    }

    try {
      _currentSoundscape = soundscapeId;
      final assetPath = soundscapeAssets[soundscapeId];

      if (assetPath == null) {
        // Silence - stop any playing audio
        await _player.stop();
        developer.log('Soundscape set to silence', name: 'SoundscapeService');
        return true;
      }

      // Try to load the asset
      try {
        await _player.setAsset(assetPath);
        developer.log(
          'Soundscape set to: $soundscapeId',
          name: 'SoundscapeService',
        );
        return true;
      } catch (e) {
        // Asset not found or empty - use fallback
        developer.log(
          'Asset not found for $soundscapeId: $e',
          name: 'SoundscapeService',
        );
        // On web, we'll just continue silently
        if (!kIsWeb) {
          await _playGeneratedNoise(soundscapeId);
        }
        return false;
      }
    } catch (e) {
      developer.log('Error setting soundscape: $e', name: 'SoundscapeService');
      return false;
    }
  }

  /// Plays the current soundscape.
  Future<void> play() async {
    if (kIsWeb) {
      WebCompletionAudio.requestWakeLock();
      WebCompletionAudio.startSessionAudio();
    }

    if (_currentSoundscape == 'silence') return;

    try {
      await _player.play();
      developer.log('Soundscape playing', name: 'SoundscapeService');
    } catch (e) {
      developer.log('Error playing soundscape: $e', name: 'SoundscapeService');
    }
  }

  /// Stops web-only session audio when a session is cancelled before completion.
  void stopWebSessionAudio() {
    if (kIsWeb) {
      WebCompletionAudio.stopSessionAudio();
      WebCompletionAudio.releaseWakeLock();
    }
  }

  /// Unlocks web audio from a user gesture so completion sounds can play later.
  Future<void> unlockForUserGesture() async {
    if (kIsWeb) {
      await WebCompletionAudio.unlock();
    }
  }

  /// Pauses the current soundscape.
  Future<void> pause() async {
    try {
      await _player.pause();
      developer.log('Soundscape paused', name: 'SoundscapeService');
    } catch (e) {
      developer.log('Error pausing soundscape: $e', name: 'SoundscapeService');
    }
  }

  /// Stops the current soundscape.
  Future<void> stop() async {
    try {
      await _player.stop();
      developer.log('Soundscape stopped', name: 'SoundscapeService');
    } catch (e) {
      developer.log('Error stopping soundscape: $e', name: 'SoundscapeService');
    }
  }

  /// Plays the completion bell sound.
  ///
  /// This is a soft, pleasant bell sound that plays when a session completes.
  Future<void> playCompletionBell() async {
    await initialize();

    try {
      if (kIsWeb && WebCompletionAudio.playBell()) {
        developer.log('Web completion bell played', name: 'SoundscapeService');
        return;
      }

      // Try to play the bell asset
      try {
        await _bellPlayer.setAsset(bellAsset);
        await _bellPlayer.setVolume(0.6); // Softer volume for completion
        await _bellPlayer.play();
        developer.log('Completion bell played', name: 'SoundscapeService');
      } catch (e) {
        // Asset not found, use system sound as fallback
        developer.log(
          'Bell asset not found, using system sound: $e',
          name: 'SoundscapeService',
        );
        await _playSystemBell();
      }
    } catch (e) {
      developer.log(
        'Error playing completion bell: $e',
        name: 'SoundscapeService',
      );
    }
  }

  /// Plays a system bell sound as fallback.
  Future<void> _playSystemBell() async {
    try {
      // Use system alert sound as fallback
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      developer.log('Error playing system bell: $e', name: 'SoundscapeService');
    }
  }

  /// Sets the volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      developer.log('Error setting volume: $e', name: 'SoundscapeService');
    }
  }

  /// Releases resources.
  Future<void> dispose() async {
    try {
      await _player.dispose();
      await _bellPlayer.dispose();
      _isInitialized = false;
      developer.log('Soundscape service disposed', name: 'SoundscapeService');
    } catch (e) {
      developer.log(
        'Error disposing soundscape service: $e',
        name: 'SoundscapeService',
      );
    }
  }

  /// Plays generated noise as a fallback.
  Future<void> _playGeneratedNoise(String type) async {
    // For now, we'll use a silent audio file or generated noise
    // In a real app, you'd generate noise programmatically or use a bundled asset
    developer.log('Using generated $type', name: 'SoundscapeService');
  }
}
