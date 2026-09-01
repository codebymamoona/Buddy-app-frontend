import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/buddy_api_service.dart';

class SignupScreen extends StatefulWidget {
  final void Function(String userId) onSignupSuccess;
  const SignupScreen({super.key, required this.onSignupSuccess});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController(); // Changed from email
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userIdCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // 🚨 THE REAL SPRING BOOT API CALL 🚨
      await BuddyApiService().signup(
          _userIdCtrl.text.trim(),
          _nameCtrl.text.trim(),
          _passwordCtrl.text
      );

      if (!mounted) return;
      setState(() => _loading = false);

      // Pass the newly created User ID straight into the session
      widget.onSignupSuccess(_userIdCtrl.text.trim());
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Fail loudly if the backend rejects the signup (e.g. ID taken or DB crash)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup Failed: $e'), backgroundColor: Colors.red),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _userIdCtrl,
                  keyboardType: TextInputType.text, // Changed to standard text
                  decoration: const InputDecoration(
                    labelText: 'User ID (e.g. shahzaib_99)', // Enforcing the tenant handle
                    prefixIcon: Icon(Icons.alternate_email, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'User ID is required';
                    if (v.contains(' ')) return 'User ID cannot contain spaces';
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
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                  validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null,
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
                      : const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}