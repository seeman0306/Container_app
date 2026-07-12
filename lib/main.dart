import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'core/utils/secure_token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool loggedIn = await SecureTokenStorage.isLoggedIn();

  runApp(SmartCityApp(startScreen: loggedIn ? const DashboardScreen() : const LoginScreen()));
}

class SmartCityApp extends StatelessWidget {
  final Widget startScreen;
  const SmartCityApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban Smart City',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: startScreen,
    );
  }
}
