import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 NEW
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
bool _isPasswordVisible = false;
bool _isConfirmVisible = false;

String? _nameError;
String? _emailError;
String? _passwordError;
String? _confirmError;
Future<void> _signup() async {
  final name = _nameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  final confirm = _confirmController.text.trim();

  setState(() {
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmError = null;
  });

  // ✅ NAME
  if (name.isEmpty) {
    setState(() => _nameError = "Name is required");
    return;
  }

  // ✅ EMAIL
  if (email.isEmpty) {
    setState(() => _emailError = "Email is required");
    return;
  }

  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
    setState(() => _emailError = "Enter valid email");
    return;
  }

  // ✅ PASSWORD
  if (password.length < 6) {
    setState(() => _passwordError = "Min 6 characters required");
    return;
  }

  // ✅ CONFIRM
  if (password != confirm) {
    setState(() => _confirmError = "Passwords do not match");
    return;
  }

  setState(() => _isLoading = true);

  try {
    final user = await _authService.signup(name, email, password);

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'name': name,
        'role': 'user',
        'createdAt': Timestamp.now(),
      });

      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }on FirebaseAuthException catch (e) {
  print("ERROR CODE: ${e.code}");
  print("ERROR MESSAGE: ${e.message}");

  if (e.code == 'email-already-in-use') {
    setState(() => _emailError = "Email already registered");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account already exists. Please login.")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${e.code}")),
    );
  }
}catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Something went wrong")),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _signupWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.loginWithGoogle();

      if (user != null) {
        // 🔥 SAVE GOOGLE USER (if not exists)
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!doc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'name': user.displayName ?? '',
            'role': 'user',
            'createdAt': Timestamp.now(),
          });
        }

        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google signup failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Create Your Account",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
               decoration: _inputDecoration("Full Name", Icons.person).copyWith(
  errorText: _nameError,
),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
               decoration: _inputDecoration("Email", Icons.email).copyWith(
  errorText: _emailError,
),
              ),
              const SizedBox(height: 20),

             

              TextField(
  controller: _passwordController,
  obscureText: !_isPasswordVisible,
  style: const TextStyle(color: Colors.white),
  decoration: _inputDecoration("Password", Icons.lock).copyWith(
    errorText: _passwordError,
    suffixIcon: IconButton(
      icon: Icon(
        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
        color: Colors.white,
      ),
      onPressed: () {
        setState(() {
          _isPasswordVisible = !_isPasswordVisible;
        });
      },
    ),
  ),
),
              const SizedBox(height: 20),
TextField(
  controller: _confirmController,
  obscureText: !_isConfirmVisible,
  style: const TextStyle(color: Colors.white),
  decoration: _inputDecoration("Confirm Password", Icons.lock).copyWith(
    errorText: _confirmError,
    suffixIcon: IconButton(
      icon: Icon(
        _isConfirmVisible ? Icons.visibility : Icons.visibility_off,
        color: Colors.white,
      ),
      onPressed: () {
        setState(() {
          _isConfirmVisible = !_isConfirmVisible;
        });
      },
    ),
  ),
),
const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading ? null : _signup,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up"),
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  "Or Sign Up with",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    onPressed: _isLoading ? null : _signupWithGoogle,
    icon: const FaIcon(FontAwesomeIcons.google, color: Colors.red),
    label: const Text("Continue with Google"),
  ),
),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.black,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white54),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}