import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'core/theme/aura_theme.dart';
import 'providers/aura_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/organization_provider.dart';
import 'services/permission_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/organization_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🏁 MAIN: WidgetsFlutterBinding initialized');

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      print('🏁 MAIN: Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('🏁 MAIN: Firebase initialized');
    } else {
      print('🏁 MAIN: Firebase already initialized');
    }
  } catch (e) {
    print('⚠️ MAIN: Firebase init error (continuing): $e');
  }

  // Set preferred orientations
  try {
    print('🏁 MAIN: Setting orientations...');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    print('🏁 MAIN: Orientations set');
  } catch (e) {
    print('⚠️ MAIN: Orientation error: $e');
  }

  // Initialize ThemeProvider
  final themeProvider = ThemeProvider();
  try {
    print('🏁 MAIN: Initializing ThemeProvider...');
    await themeProvider.init();
    print('🏁 MAIN: ThemeProvider initialized');
  } catch (e) {
    print('⚠️ MAIN: ThemeProvider error: $e');
  }

  // Initialize NotificationService
  try {
    print('🏁 MAIN: Initializing NotificationService...');
    await NotificationService().init();
    print('🏁 MAIN: NotificationService initialized');
  } catch (e) {
    print('⚠️ MAIN: NotificationService error: $e');
  }

  print('🏁 MAIN: Calling runApp...');
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
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/organization': (context) => const OrganizationScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Widget que decide si mostrar Login o Home basado en el estado de auth
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('🔒 AuthWrapper: Building...');
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('🔒 AuthWrapper: Stream update. State: ${snapshot.connectionState}, HasData: ${snapshot.hasData}');
        
        // Mientras carga, mostrar splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('🔒 AuthWrapper: Waiting for auth state...');
          return const SplashScreen();
        }
        
        // Si hay usuario, mostrar home
        if (snapshot.hasData) {
          print('🔒 AuthWrapper: User logged in: ${snapshot.data?.uid}');
          return const SplashScreen(skipAuth: true);
        }
        
        // Si no hay usuario, mostrar login
        print('🔒 AuthWrapper: No user, showing LoginScreen');
        return const LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  final bool skipAuth;
  
  const SplashScreen({super.key, this.skipAuth = false});

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
    print('✨ SplashScreen: initState');
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
      print('🚀 SplashScreen: Requesting permissions...');
      setState(() => _statusText = 'Requesting permissions...');
      
      final permissionService = PermissionService();
      // Timeout permissions request to avoid hanging forever
      await permissionService.requestAllPermissions().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ SplashScreen: Permissions request timed out');
          return {};
        },
      );
      print('✅ SplashScreen: Permissions done');

      // Initialize provider
      print('🚀 SplashScreen: Loading AI models...');
      setState(() => _statusText = 'Loading AI models...');
      
      if (!mounted) return;
      final provider = context.read<AuraProvider>();
      await provider.initialize();
      print('✅ SplashScreen: Provider initialized');

      setState(() => _statusText = 'Ready!');
      await Future.delayed(const Duration(milliseconds: 500));
      print('✅ SplashScreen: Navigating to home...');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('❌ SplashScreen: Error - $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusText = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('✨ SplashScreen: build called. Status: $_statusText');
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? AuraColors.backgroundDark : AuraColors.backgroundLight;
    final textColor = AuraColors.getAccentColor(isDark);
    
    return Scaffold(
      backgroundColor: bgColor,
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
                    // Logo real de la app
                    Image.asset(
                      'assets/icons/aura_logo.png',
                      width: 140,
                      height: 140,
                    ),
                    const SizedBox(height: 32),

                    // App Name
                    Text(
                      'Aura',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Your AI Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 64),

                    // Loading indicator or error
                    if (!_hasError) ...[
                      SizedBox(
                        width: 180,
                        child: LinearProgressIndicator(
                          backgroundColor: textColor.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            textColor.withValues(alpha: 0.8),
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
                            : textColor.withValues(alpha: 0.5),
                      ),
                    ),

                    // Retry button if error
                    if (_hasError) ...[
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _statusText = 'Initializing...';
                          });
                          _initializeApp();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: textColor),
                          foregroundColor: textColor,
                        ),
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
