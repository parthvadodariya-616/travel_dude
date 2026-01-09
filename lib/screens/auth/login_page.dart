// lib/screens/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../home/home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Helpers.showSnackBar(context, 'Welcome back!');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else if (mounted) {
        Helpers.showSnackBar(
          context, 
          authProvider.error ?? 'Login failed.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      Helpers.showSnackBar(context, 'Please enter your email first', isError: true);
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.resetPassword(email);
      if (mounted) Helpers.showSnackBar(context, 'Password reset email sent!');
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF13DAEC);
    final backgroundColor = isDark ? const Color(0xFF102022) : const Color(0xFFF6F8F8);
    final surfaceColor = isDark ? const Color(0xFF1A2C30) : Colors.white;
    final textMainColor = isDark ? Colors.white : const Color(0xFF0D1A1B);
    final textSubColor = isDark ? const Color(0xFF8FBABE) : const Color(0xFF4C939A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 72),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.2, color: textMainColor),
                      children: [
                        const TextSpan(text: 'Welcome\n'),
                        TextSpan(text: 'back.', style: TextStyle(color: primaryColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Sign in to continue your adventure.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSubColor)),
                  const SizedBox(height: 40),
                  
                  Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMainColor)),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _emailController,
                    hint: 'your.email@example.com',
                    icon: Icons.email_outlined,
                    surfaceColor: surfaceColor,
                    textMainColor: textMainColor,
                    textSubColor: textSubColor,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 20),

                  Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMainColor)),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _passwordController,
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    surfaceColor: surfaceColor,
                    textMainColor: textMainColor,
                    textSubColor: textSubColor,
                    isPassword: true,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 20, width: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: isLoading ? null : (val) => setState(() => _rememberMe = val ?? false),
                              activeColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember me', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSubColor)),
                        ],
                      ),
                      TextButton(
                        onPressed: isLoading ? null : _handleForgotPassword,
                        child: Text('Forgot password?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSubColor)),
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                        child: Text('Sign Up', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color surfaceColor,
    required Color textMainColor,
    required Color textSubColor,
    required bool isLoading,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        enabled: !isLoading,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMainColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textSubColor.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: textSubColor, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: textSubColor, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}