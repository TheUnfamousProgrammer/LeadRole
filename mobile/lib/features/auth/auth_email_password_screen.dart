import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leadrole/features/auth/auth_controller.dart';
import '../../../shared/colors.dart';

class AuthEmailPasswordScreen extends ConsumerStatefulWidget {
  const AuthEmailPasswordScreen({super.key});

  @override
  ConsumerState<AuthEmailPasswordScreen> createState() =>
      _AuthEmailPasswordScreenState();
}

class _AuthEmailPasswordScreenState
    extends ConsumerState<AuthEmailPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _pwdFocus = FocusNode();

  bool _isSignup = true;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _emailFocus.dispose();
    _pwdFocus.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final e = _emailCtrl.text.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  bool get _pwdValid => _pwdCtrl.text.length >= 6;

  Future<void> _submit() async {
    final auth = ref.read(authProvider.notifier);
    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text;

    if (!_emailValid || !_pwdValid) {
      HapticFeedback.mediumImpact();
      return;
    }

    try {
      if (_isSignup) {
        await auth.doSignup(email, pwd);
      } else {
        await auth.doLogin(email, pwd);
      }
      if (mounted) context.go('/persona');
    } catch (_) {
      if (!mounted) return;
      final msg = ref.read(authProvider).error ?? 'Something went wrong';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final loading = state.loading;

    final canSubmit = _emailValid && _pwdValid && !loading;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Casting Call'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('New Talent (Sign Up)'),
                    selected: _isSignup,
                    onSelected: (_) => setState(() => _isSignup = true),
                    selectedColor: AppColors.neon,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isSignup ? Colors.black : Colors.white,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Returning Talent (Log In)'),
                    selected: !_isSignup,
                    onSelected: (_) => setState(() => _isSignup = false),
                    selectedColor: AppColors.neon,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: !_isSignup ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => _pwdFocus.requestFocus(),
                autocorrect: false,
                enableSuggestions: false,
                decoration: _decoration('Email').copyWith(
                  suffixIcon: _emailCtrl.text.isEmpty
                      ? null
                      : Icon(
                          _emailValid ? Icons.check_circle : Icons.error,
                          size: 20,
                          color: _emailValid
                              ? AppColors.neon
                              : Colors.redAccent,
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwdCtrl,
                focusNode: _pwdFocus,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
                decoration:
                    _decoration(
                      _isSignup ? 'Create password (min 6)' : 'Password',
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (state.error != null && state.error!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.redAccent.withOpacity(0.12),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              const Spacer(),
              Text(
                'By continuing, you agree to the Terms of Service.',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSubmit
                        ? AppColors.neon
                        : AppColors.neon.withOpacity(0.4),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: canSubmit ? 2 : 0,
                  ),
                  onPressed: canSubmit ? _submit : null,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CupertinoActivityIndicator(
                            color: Colors.black,
                            radius: 10,
                          ),
                        )
                      : Text(
                          _isSignup ? 'Create Account' : 'Log In',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.neon.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.neon, width: 1.6),
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
      fillColor: const Color(0xFF222222),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
