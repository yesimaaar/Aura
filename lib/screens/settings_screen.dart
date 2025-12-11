import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/aura_theme.dart';
import '../providers/aura_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auraProvider = Provider.of<AuraProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: AuraColors.getBackgroundColor(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AuraColors.getTextPrimary(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuración',
          style: TextStyle(color: AuraColors.getTextPrimary(isDark)),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Perfil Section
                    if (user != null) ...[
                      _buildSection(
                        context,
                        title: 'Perfil',
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AuraColors.getSurfaceColor(isDark),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: user.photoURL != null 
                                      ? NetworkImage(user.photoURL!) 
                                      : null,
                                  backgroundColor: AuraColors.primaryPurple,
                                  child: user.photoURL == null 
                                      ? Text(
                                          user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                          style: const TextStyle(fontSize: 24, color: Colors.white),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName ?? 'Usuario',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AuraColors.getTextPrimary(isDark),
                                        ),
                                      ),
                                      Text(
                                        user.email ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AuraColors.getTextMuted(isDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsTile(
                            icon: Icons.edit_outlined,
                            title: 'Editar perfil',
                            subtitle: 'Cambiar nombre o foto',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Próximamente: Editar perfil')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    _buildSection(
                      context,
                      title: 'General',
                      children: [
                        _SettingsTile(
                          icon: Icons.dark_mode_rounded,
                          title: 'Modo Oscuro',
                          subtitle: themeProvider.isDarkMode ? 'Activado' : 'Desactivado',
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
                          icon: Icons.logout_rounded,
                          title: 'Cerrar Sesión',
                          subtitle: 'Salir de la cuenta',
                          textColor: Colors.redAccent,
                          iconColor: Colors.redAccent,
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                            }
                          },
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            'Aura v1.0.0',
                            style: TextStyle(
                              color: AuraColors.getTextMuted(isDark),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AuraColors.getTextSecondary(isDark),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AuraColors.getSurfaceColor(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? AuraColors.getTextPrimary(isDark)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AuraColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor ?? AuraColors.getTextPrimary(isDark),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AuraColors.getTextMuted(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null && onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AuraColors.getTextMuted(isDark),
                ),
            ],
          ),
        ),
      ),
    );
  }
}