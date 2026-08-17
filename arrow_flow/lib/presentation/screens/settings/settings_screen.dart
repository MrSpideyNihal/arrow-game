import 'package:flutter/material.dart';
import '../../../l10n/app_strings.dart';
import '../../../main.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/storage_service.dart';

/// Settings screen with toggles for audio, haptics, and reset progress.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _sfxEnabled;
  late bool _musicEnabled;
  late bool _hapticsEnabled;

  @override
  void initState() {
    super.initState();
    final storage = StorageService();
    _sfxEnabled = storage.getSetting<bool>('sfx_enabled', defaultValue: appConfig.audio.sfxEnabledDefault)!;
    _musicEnabled = storage.getSetting<bool>('music_enabled', defaultValue: appConfig.audio.musicEnabledDefault)!;
    _hapticsEnabled = storage.getSetting<bool>('haptics_enabled', defaultValue: appConfig.audio.hapticsEnabledDefault)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.settings,
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _ToggleTile(
                        icon: Icons.volume_up_rounded,
                        label: AppStrings.soundEffects,
                        value: _sfxEnabled,
                        accentColor: theme.colorScheme.primary,
                        onChanged: (v) {
                          setState(() => _sfxEnabled = v);
                          AudioService(config: appConfig.audio).toggleSfx(v);
                        },
                      ),
                      const Divider(height: 1),
                      _ToggleTile(
                        icon: Icons.music_note_rounded,
                        label: AppStrings.music,
                        value: _musicEnabled,
                        accentColor: theme.colorScheme.primary,
                        onChanged: (v) {
                          setState(() => _musicEnabled = v);
                          AudioService(config: appConfig.audio).toggleMusic(v);
                        },
                      ),
                      const Divider(height: 1),
                      _ToggleTile(
                        icon: Icons.vibration_rounded,
                        label: AppStrings.haptics,
                        value: _hapticsEnabled,
                        accentColor: theme.colorScheme.primary,
                        onChanged: (v) {
                          setState(() => _hapticsEnabled = v);
                          StorageService().saveSetting('haptics_enabled', v);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Reset progress.
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      ListTile(
                        leading: Icon(Icons.restart_alt_rounded,
                            color: Colors.redAccent.shade100),
                        title: Text(AppStrings.resetProgress,
                            style: theme.textTheme.bodyLarge),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: () => _showResetConfirmation(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Version info.
                  Center(
                    child: Text(
                      '${appConfig.app.name} v${appConfig.app.version}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.resetProgress,
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(AppStrings.resetConfirm,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(AppStrings.cancel),
                  ),
                    ElevatedButton(
                      onPressed: () async {
                        await StorageService().resetAllProgress();
                        if (context.mounted) Navigator.of(ctx).pop();
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade100,
                    ),
                    child: const Text(AppStrings.confirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0xFF1E2028) : const Color(0xFFFFFFFF),
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: isDark ? const Color(0xFF0A0B0E) : const Color(0xFFBEC3CF),
            offset: const Offset(3, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: Icon(icon, size: 22),
      title: Text(label, style: theme.textTheme.bodyLarge),
      value: value,
      activeThumbColor: accentColor,
      onChanged: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
