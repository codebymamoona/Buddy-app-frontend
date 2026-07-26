import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/buddy_api_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String email) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _api = BuddyApiService();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = _userIdCtrl.text.trim();

      if (!mounted) return;
      setState(() => _loading = false);

      // Pass the backend-compatible User ID handle forward
      widget.onLoginSuccess(userId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Login failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    height: 72,
                    width: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.smart_toy_outlined, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Log in to connect with your AI Buddy',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _userIdCtrl,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'User ID (e.g. shahzaib_99)',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'User ID is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Log In'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?", style: TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SignupScreen(onSignupSuccess: widget.onLoginSuccess),
                            ),
                          );
                        },
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}