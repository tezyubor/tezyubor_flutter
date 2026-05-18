import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kHapticKey = 'haptic_enabled';

class HapticService {
  static bool _enabled = true;

  static void update(bool value) => _enabled = value;

  static void light() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (_enabled) HapticFeedback.selectionClick();
  }
}

class HapticEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_kHapticKey) ?? true;
    state = enabled;
    HapticService.update(enabled);
  }

  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;
    HapticService.update(newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHapticKey, newValue);
  }
}

final hapticEnabledProvider = NotifierProvider<HapticEnabledNotifier, bool>(
  HapticEnabledNotifier.new,
);
