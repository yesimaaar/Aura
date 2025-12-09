import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/aura_theme.dart';
import 'providers/aura_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/organization_provider.dart';
import 'services/permission_service.dart';
import 'screens/home_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/organization_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize ThemeProvider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(AuraApp(themeProvider: themeProvider));
}

class AuraApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const AuraApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuraProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => OrganizationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Update system UI based on theme
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeProvider.isDarkMode
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: themeProvider.isDarkMode
                  ? AuraColors.bottomNavDark
                  : AuraColors.bottomNavLight,
              systemNavigationBarIconBrightness: themeProvider.isDarkMode
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: 'Aura',
            debugShowCheckedModeBanner: false,
            theme: AuraTheme.lightTheme,
            darkTheme: AuraTheme.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/editor': (context) => const EditorScreen(),
              '/organization': (context) => const OrganizationScreen(),
            },
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _statusText = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Request permissions
      setState(() => _statusText = 'Requesting permissions...');
      final permissionService = PermissionService();
      await permissionService.requestAllPermissions();

      // Initialize provider
      setState(() => _statusText = 'Loading AI models...');
      final provider = context.read<AuraProvider>();
      await provider.initialize();

      setState(() => _statusText = 'Ready!');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _statusText = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.backgroundDark,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo - mantiene gradiente solo aquí
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AuraColors.auraGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Name - mantiene gradiente solo para "Aura"
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AuraColors.auraGradient.createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                      child: const Text(
                        'Aura',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'AI-Powered Visual Enhancement',
                      style: TextStyle(
                        fontSize: 16,
                        color: AuraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Loading indicator or error
                    if (!_hasError) ...[
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          backgroundColor: AuraColors.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.error_outline,
                        color: AuraColors.error,
                        size: 48,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Status text
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 14,
                        color: _hasError
                            ? AuraColors.error
                            : AuraColors.textMuted,
                      ),
                    ),

                    // Retry button if error
                    if (_hasError) ...[
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _statusText = 'Initializing...';
                          });
                          _initializeApp();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
