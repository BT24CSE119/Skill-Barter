import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String role = "user";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      role = args;
    }
  }

  @override
Future<void> _loginWithGoogle() async {
  setState(() => _isLoading = true);

  try {
    final user = await _authService.loginWithGoogle();

    if (user == null) return;

    final email = user.email ?? "";

    /// 🔥 ADMIN LOGIN PAGE
    if (role == "admin") {
      if (email != "iamharish0011@gmail.com") {
        _showSnack("Only admin allowed here");
        await _authService.logout();
        return;
      }

      Navigator.pushReplacementNamed(context, '/admin');
      return;
    }

    /// 🔥 USER LOGIN PAGE
    if (role == "user") {

      /// Admin email allowed as normal user
      if (email == "iamharish0011@gmail.com") {
        Navigator.pushReplacementNamed(context, '/dashboard');
        return;
      }

      /// Only IIITN BT emails allowed
      final isBT = RegExp(r'^bt\d{2}(cse|ece|csd|aiml)\d{3}@iiitn\.ac\.in$')
          .hasMatch(email);

      if (!isBT) {
        _showSnack("Enter valid college email");
        await _authService.logout();
        return;
}

      Navigator.pushReplacementNamed(context, '/dashboard');
      return;
    }

    /// 🔥 FALLBACK ROLE CHECK
    final userRole = await _authService.getUserRole(user.uid);
    _navigateByRole(userRole);

  } catch (e) {
    _showSnack("Google login failed");
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  /// ================= NAVIGATION =================
  void _navigateByRole(String role) {
    if (!mounted) return;
    if (role == "superadmin") {
      Navigator.pushReplacementNamed(context, '/superadmin');
    } else if (role == "admin") {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
  alignment: Alignment.centerLeft,
  child: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () {
      Navigator.pushReplacementNamed(context, '/role');
    },
  ),
),
              const SizedBox(height: 20),
              
              Text(
                role == "admin"
                    ? "Admin Portal 👑"
                    : role == "superadmin"
                        ? "Super Admin Access 🚀"
                        : "Welcome Back!",
                style: AppTextStyles.heading.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Sign in to continue skill bartering",
                style: TextStyle(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Or continue with", style: TextStyle(color: Colors.white38)),
                  ),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 30),

              // SOCIAL BUTTONS
              SizedBox(
  width: double.infinity,
  child: _socialButton(
    label: "Continue with Google",
    icon: FontAwesomeIcons.google,
    iconColor: Colors.red,
    onTap: _loginWithGoogle,
  ),
),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white54, size: 22),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white12),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
       padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}