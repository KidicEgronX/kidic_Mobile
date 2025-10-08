import 'package:flutter/material.dart';
// Auth pages
import 'package:kidicapp_flutter/pages/auth/login_page.dart';
import 'package:kidicapp_flutter/pages/auth/signup_page.dart';
import 'package:kidicapp_flutter/pages/auth/kidic_intro.dart';
import 'package:kidicapp_flutter/pages/auth/user_data.dart';
// Main pages
import 'package:kidicapp_flutter/pages/main/home_page.dart';
import 'package:kidicapp_flutter/pages/main/main_navigation.dart';
// Profile pages
import 'package:kidicapp_flutter/pages/profile/profile.dart';
// Child pages
import 'package:kidicapp_flutter/pages/child/child_tracker_page.dart';
import 'package:kidicapp_flutter/pages/child/growth_page.dart';
// Feature pages
import 'package:kidicapp_flutter/pages/features/education_page.dart';
import 'package:kidicapp_flutter/pages/features/emergency_page.dart';
import 'package:kidicapp_flutter/pages/features/chatbot_page.dart';
import 'package:kidicapp_flutter/pages/features/meals_page.dart';
import 'package:kidicapp_flutter/pages/features/smart_store_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String intro = '/intro';
  static const String signup = '/signup';
  static const String userData = '/user-data';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String mainNavigation = '/main-navigation';
  static const String childTracker = '/child-tracker';
  static const String growth = '/growth';
  static const String education = '/education';
  static const String emergency = '/emergency';
  static const String chatbot = '/chatbot';
  static const String meals = '/meals';
  static const String smartStore = '/smart-store';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => const HomePage());
    case AppRoutes.intro:
      return MaterialPageRoute(builder: (_) => const KidicIntroPage());
    case AppRoutes.signup:
      return MaterialPageRoute(builder: (_) => const SignupPage());
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginPage());
    case AppRoutes.profile:
      return MaterialPageRoute(
        builder: (_) =>
            const ProfilePage(), // No userData needed - uses JWT token
      );
    case AppRoutes.mainNavigation:
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => MainNavigationPage(
          initialIndex: args?['initialIndex'] ?? 0,
          // No userData needed - pages use JWT token to get data
        ),
      );
    case AppRoutes.userData:
      // For user data page, we expect arguments to be passed
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => UserDataPage(
          userData: args?['userData'] ?? {},
          messages: args?['messages'],
        ),
      );
    case AppRoutes.childTracker:
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => ChildTrackerPage(arguments: args),
      );
    case AppRoutes.growth:
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: GrowthTab()),
      );
    case AppRoutes.education:
      return MaterialPageRoute(builder: (_) => const EducationPage());
    case AppRoutes.emergency:
      return MaterialPageRoute(builder: (_) => const EmergencyPage());
    case AppRoutes.chatbot:
      return MaterialPageRoute(builder: (_) => const ChatbotPage());
    case AppRoutes.meals:
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => MealsPage(initialChildId: args?['childId']),
      );
    case AppRoutes.smartStore:
      return MaterialPageRoute(builder: (_) => const SmartStorePage());
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('No route defined for ${settings.name}')),
        ),
      );
  }
}
