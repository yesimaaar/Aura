import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/aura_theme.dart';
import '../providers/aura_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/aura_gradient_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auraProvider = Provider.of<AuraProvider>(context);
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      context,
                      title: 'General',
                      children: [
                        _SettingsTile(
                          icon: Icons.dark_mode_rounded,
                          title: 'Dark Mode',
                          subtitle: themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (v) => themeProvider.setDarkMode(v),
                            activeTrackColor: AuraColors.primaryPurple,
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.auto_awesome_rounded,
                          title: 'Auto Enhance',
                          subtitle: 'Apply AI enhancements automatically',
                          trailing: Switch(
                            value: false,
                            onChanged: (v) {},
                            activeTrackColor: AuraColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Inteligencia Artificial',
                      children: [
                        _SettingsTile(
                          icon: Icons.psychology_rounded,
                          title: 'Gemini 2.0 Flash',
                          subtitle: 'Modelo de IA para análisis',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: auraProvider.isGeminiReady 
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              auraProvider.isGeminiReady ? 'Activo' : 'Demo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: auraProvider.isGeminiReady 
                                    ? Colors.green 
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Camera',
                      children: [
                        _SettingsTile(
                          icon: Icons.high_quality_rounded,
                          title: 'Image Quality',
                          subtitle: 'High',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.save_rounded,
                          title: 'Save Original',
                          subtitle: 'Keep original when editing',
                          trailing: Switch(
                            value: true,
                            onChanged: (v) {},
                            activeTrackColor: AuraColors.primaryPurple,
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.grid_on_rounded,
                          title: 'Grid Overlay',
                          subtitle: 'Show composition guides',
                          trailing: Switch(
                            value: false,
                            onChanged: (v) {},
                            activeTrackColor: AuraColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Storage',
                      children: [
                        _SettingsTile(
                          icon: Icons.folder_rounded,
                          title: 'Storage Location',
                          subtitle: 'App Documents',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.delete_sweep_rounded,
                          title: 'Clear Cache',
                          subtitle: 'Free up space',
                          onTap: () => _showClearCacheDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'About',
                      children: [
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Version',
                          subtitle: '1.0.0',
                        ),
                        _SettingsTile(
                          icon: Icons.description_rounded,
                          title: 'Privacy Policy',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.gavel_rounded,
                          title: 'Terms of Service',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.code_rounded,
                          title: 'Open Source Licenses',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: AuraColors.auraGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const AuraGradientText(
                            'Aura',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI-Powered Visual Enhancement',
                            style: TextStyle(
                              color: AuraColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              color: AuraColors.primaryPurple,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AuraColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuraColors.backgroundCard,
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will remove temporary files. Your photos will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Cache cleared'),
                  backgroundColor: AuraColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AuraColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AuraColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AuraColors.textSecondary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: AuraColors.textMuted,
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: AuraColors.textMuted,
                )
              : null),
      onTap: onTap,
    );
  }
}
