// lib/screens/auth/signup_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../home/home_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      Helpers.showSnackBar(context, 'Please agree to Terms & Conditions', isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      Helpers.showSnackBar(context, 'Passwords do not match', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (success && mounted) {
        Helpers.showSnackBar(context, 'Account created successfully!');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else if (mounted) {
        Helpers.showSnackBar(
          context, 
          authProvider.error ?? 'Signup failed.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Error: $e', isError: true);
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
                  const SizedBox(height: 40),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 40, width: 40,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Icon(Icons.arrow_back, color: textMainColor, size: 20),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.2, color: textMainColor),
                      children: [
                        const TextSpan(text: 'Create\n'),
                        TextSpan(text: 'account.', style: TextStyle(color: primaryColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Start your travel adventure today.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSubColor)),
                  const SizedBox(height: 32),

                  _buildTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    hint: 'John Doe',
                    surfaceColor: surfaceColor,
                    textMainColor: textMainColor,
                    textSubColor: textSubColor,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: 'your.email@example.com',
                    surfaceColor: surfaceColor,
                    textMainColor: textMainColor,
                    textSubColor: textSubColor,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Password',
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    hint: 'Min. 8 characters',
                    isPassword: true,
                    isObscure: _obscurePassword,
                    onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    surfaceColor: surfaceColor,
                    textMainColor: textMainColor,
                    textSubColor: textSubColor,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline,
                    hint: 'Re-enter password',
                    isPassword: true,
                    isObscure: _obscureConfirmPassword,
                    onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    surfaceColor: surfaceColor,
                    textMainColor: textMainColor,
                    textSubColor: textSubColor,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      SizedBox(
                        height: 20, width: 20,
                        child: Checkbox(
                          value: _agreeToTerms,
                          onChanged: isLoading ? null : (val) => setState(() => _agreeToTerms = val ?? false),
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('I agree to the Terms & Conditions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSubColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (isLoading || !_agreeToTerms) ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSubColor)),
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        child: Text('Sign In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor)),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color surfaceColor,
    required Color textMainColor,
    required Color textSubColor,
    required bool isLoading,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMainColor)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isObscure,
            enabled: !isLoading,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMainColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textSubColor.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: textSubColor, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: textSubColor, size: 20),
                      onPressed: onToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}