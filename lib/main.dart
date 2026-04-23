import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/language/language_provider.dart'; // 🔥 create this file if not
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'services/notification_service.dart';
// 🔥 COMMENTED OUT UNTIL YOU CREATE THE FILE:
// import 'screens/admin/super_admin_screen.dart'; 

import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/notifications/notifications_screen.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

/// ================= GLOBAL NAVIGATOR =================
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ================= BACKGROUND HANDLER =================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const SkillBarterApp());
}

class SkillBarterApp extends StatefulWidget {
  const SkillBarterApp({super.key});

  @override
  State<SkillBarterApp> createState() => _SkillBarterAppState();
}

class _SkillBarterAppState extends State<SkillBarterApp> {

  @override
  void initState() {
    super.initState();
    NotificationService.init();
  }

  // ================= ROLE BASED HOME =================
  Future<Widget> _getInitialScreen() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SplashScreen();
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final role = doc.data()?['role'] ?? 'user';

    if (role == "superadmin") {
      // 🔥 TEMPORARY FALLBACK UNTIL FILE IS CREATED
      return const Scaffold(body: Center(child: Text("Super Admin Coming Soon")));
    } else if (role == "admin") {
      return const AdminScreen();
    } else {
      return const DashboardScreen();
    }
  }

  /// ================= UI =================
  @override
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) {
          final provider = ThemeProvider();
          provider.loadThemePreference();
          return provider;
        },
      ),

      /// 🌐 LANGUAGE PROVIDER
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
      ),
    ],

    child: Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, langProvider, _) {
        return FutureBuilder<Widget>(
          future: _getInitialScreen(),

          builder: (context, snapshot) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: "SkillBarter",
              debugShowCheckedModeBanner: false,

              /// 🌐 LANGUAGE SUPPORT
              locale: langProvider.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('hi'),
              ],
              localizationsDelegates: const [
  // AppLocalizations.delegate,   // 🔥 ADD THIS
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],

              /// 🎨 THEME
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light,

              /// 🏠 HOME SCREEN
              home: snapshot.connectionState == ConnectionState.done
                  ? snapshot.data
                  : const SplashScreen(),

              /// 🔀 ROUTES
              routes: {
                '/splash': (context) => const SplashScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
                '/role': (context) => const RoleSelectionScreen(),

                '/login': (context) => const LoginScreen(),

                /// 🔥 ADMIN
                '/role-selector': (context) => const RoleSelectionScreen(),
                '/admin-login': (context) => const AdminLoginScreen(),
                '/admin': (context) => const AdminScreen(),

                /// USER
                '/dashboard': (context) => const DashboardScreen(),
                '/leaderboard': (context) => const LeaderboardScreen(),
                '/notifications': (context) => const NotificationsScreen(),
              },
            );
          },
        );
      },
    ),
  );
}
}