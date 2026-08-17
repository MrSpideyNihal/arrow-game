/// UI copy strings. All user-visible text lives here, not inline in widgets.
/// This makes re-skinning, translation, and copy edits trivial.
///
/// In a full l10n setup this would use Flutter's intl/arb system.
/// For now, a static class keeps things simple while maintaining the
/// "one place for all copy" discipline.
class AppStrings {
  AppStrings._();

  // Splash
  static const String splashSubtitle = 'Tap. Clear. Flow.';

  // Main Menu
  static const String play = 'Play';
  static const String dailyChallenge = 'Daily Challenge';
  static const String profile = 'Profile';
  static const String settings = 'Settings';

  // Gameplay HUD
  static const String hint = 'Hint';
  static const String pause = 'Pause';
  static const String arrowsRemaining = 'Arrows Left';

  // Combo tiers
  static const String comboX2 = 'x2';
  static const String comboX3 = 'x3';
  static const String flowState = 'FLOW STATE';

  // Level Complete
  static const String levelComplete = 'Level Complete';
  static const String nextLevel = 'Next Level';
  static const String mainMenu = 'Main Menu';
  static const String sparksEarned = 'Sparks Earned';

  // Level Select
  static const String selectLevel = 'Select Level';

  // Settings
  static const String soundEffects = 'Sound Effects';
  static const String music = 'Music';
  static const String haptics = 'Haptics';
  static const String resetProgress = 'Reset Progress';
  static const String resetConfirm = 'This will erase all progress. Continue?';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';

  // Profile / Me
  static const String awards = 'Awards';
  static const String achievements = 'Achievements';
  static const String help = 'Help';
  static const String about = 'About';
  static const String privacyRights = 'Privacy Rights';
  static const String privacyPreferences = 'Privacy Preferences';
  static const String removeAds = 'Remove Ads';

  // Economy
  static const String sparks = 'Sparks';
  static const String secondWind = 'Second Wind';
  static const String watchAd = 'Watch Ad';
  static const String notEnoughSparks = 'Not enough Sparks';

  // Cosmetics
  static const String skins = 'Skins';
  static const String themes = 'Themes';
  static const String locked = 'Locked';
  static const String unlocked = 'Unlocked';

  // Errors / fallback
  static const String error = 'Something went wrong';
  static const String retry = 'Retry';
  static const String adNotReady = 'Ad not available right now';
}
