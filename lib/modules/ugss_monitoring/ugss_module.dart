import 'package:flutter/material.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';
import 'modules/citizen/screens/citizen_home.dart';
import 'modules/field_officer/screens/officer_dashboard.dart';
import 'modules/junior_engineer/screens/je_dashboard.dart';
import 'modules/operator/screens/operator_dashboard.dart';
import 'modules/commissioner/screens/commissioner_dashboard.dart';
import 'package:smart_city_container/core/theme/app_colors.dart';

class UgssModule extends StatefulWidget {
  const UgssModule({super.key});

  @override
  State<UgssModule> createState() => _UgssModuleState();
}

class _UgssModuleState extends State<UgssModule> {
  bool _isLoading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await SecureTokenStorage.getRole();
    setState(() {
      _role = role;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine entry point based on role
    Widget home;
    switch (_role) {
      case 'FIELD_OFFICER':
        home = const OfficerDashboard();
        break;
      case 'JUNIOR_ENGINEER':
        home = const JEDashboard();
        break;
      case 'OPERATOR':
        home = const OperatorDashboard();
        break;
      case 'COMMISSIONER':
        home = const CommissionerDashboard();
        break;
      case 'CITIZEN':
      default:
        home = const CitizenHome();
        break;
    }

    return Theme(
      data: _buildTheme(),
      child: home,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

