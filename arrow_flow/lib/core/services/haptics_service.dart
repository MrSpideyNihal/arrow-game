import 'package:flutter/services.dart';

/// Haptics service providing micro-haptic feedback.
class HapticsService {
  bool _enabled = true;

  bool get isEnabled => _enabled;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Light tap feedback for standard button/arrow taps.
  Future<void> tap() async {
    if (_enabled) await HapticFeedback.lightImpact();
  }

  /// Medium feedback for valid arrow removal.
  Future<void> remove() async {
    if (_enabled) await HapticFeedback.mediumImpact();
  }

  /// Heavy feedback for combo tier-up or FLOW STATE.
  Future<void> comboTier() async {
    if (_enabled) await HapticFeedback.heavyImpact();
  }

  /// Success vibration for level completion.
  Future<void> levelComplete() async {
    if (_enabled) {
      await HapticFeedback.vibrate();
    }
  }
}
