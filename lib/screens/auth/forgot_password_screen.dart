import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    setState(() {
      _error = null;
    });

    if (email.isEmpty) {
      setState(() => _error = "Email is required");
      return;
    }

    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      setState(() => _error = "Enter a valid email");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reset link sent! Check your email."),
        ),
      );

      Navigator.pop(context); // go back to login
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() => _error = "No account found with this email");
      } else {
        setState(() => _error = "Something went wrong");
      }
    } catch (e) {
      setState(() => _error = "Error occurred");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Text(
              "Enter your email to receive reset link",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: const TextStyle(color: Colors.white54),
                errorText: _error,
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send Reset Link"),
            ),
          ],
        ),
      ),
    );
  }
}