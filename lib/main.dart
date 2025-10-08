import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidicapp_flutter/routes.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const KidicApp());
}

class KidicApp extends StatelessWidget {
  const KidicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidicApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AppInitializer(),
      onGenerateRoute: generateRoute,
      navigatorObservers: [routeObserver],
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;

    if (mounted) {
      if (hasSeenIntro) {
        // User has seen intro before, go to signup
        Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
      } else {
        // First time user, show intro
        Navigator.of(context).pushReplacementNamed(AppRoutes.intro);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
