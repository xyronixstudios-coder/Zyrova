import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  int _step = 0;
  String? _question;
  bool _loading = false;

  Future<void> _loadQuestion(AppStrings t) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack(t.invalidEmail, AppColors.error);
      return;
    }

    setState(() => _loading = true);
    final q = await AuthService.getSecurityQuestion(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _question = q;
    });

    if (q == null || q.isEmpty) {
      _snack(t.userNotFound, AppColors.error);
    } else {
      setState(() => _step = 1);
    }
  }

  Future<void> _verifyAnswer(AppStrings t) async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) {
      _snack(t.securityAnswerRequired, AppColors.error);
      return;
    }

    setState(() => _loading = true);
    final ok = await AuthService.verifySecurityAnswer(
      email: _emailCtrl.text.trim(),
      answer: answer,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      setState(() => _step = 2);
      _snack(t.verified, AppColors.success);
    } else {
      _snack(t.securityAnswerWrong, AppColors.error);
    }
  }

  Future<void> _resetPassword(AppStrings t) async {
    final newPass = _newPassCtrl.text;
    if (newPass.length < 6) {
      _snack(t.newPasswordShort, AppColors.error);
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.resetPasswordWithSecurity(
        email: _emailCtrl.text.trim(),
        newPassword: newPass,
      );
      if (!mounted) return;
      _snack(t.passwordUpdated, AppColors.success);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('${t.error}: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _answerCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(t.forgotPassword,
            style: TextStyle(color: AppColors.text)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: List.generate(3, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            active ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              if (_step == 0) _stepEmail(t),
              if (_step == 1) _stepAnswer(t),
              if (_step == 2) _stepNewPassword(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepEmail(AppStrings t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.shield, color: AppColors.primary, size: 80),
        const SizedBox(height: 20),
        Text(t.resetPassword,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(t.resetPasswordDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
        const SizedBox(height: 32),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: AppColors.text),
          decoration: _inputDecor(t.email, Icons.email),
          onSubmitted: (_) => _loadQuestion(t),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : () => _loadQuestion(t),
          style: _btnStyle(),
          child: _loading
              ? _spinner()
              : Text(t.continueText,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _stepAnswer(AppStrings t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.help_outline, color: AppColors.primary, size: 80),
        const SizedBox(height: 20),
        Text(t.securityQuestionTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(Icons.quiz, color: AppColors.primary, size: 28),
              const SizedBox(height: 12),
              Text(
                _question ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _answerCtrl,
          style: TextStyle(color: AppColors.text),
          decoration: _inputDecor(t.securityAnswerHint, Icons.lock_outline),
          onSubmitted: (_) => _verifyAnswer(t),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : () => _verifyAnswer(t),
          style: _btnStyle(),
          child: _loading
              ? _spinner()
              : Text(t.verify,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _step = 0;
            _question = null;
            _answerCtrl.clear();
          }),
          child: Text('← ${t.back}',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _stepNewPassword(AppStrings t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle, color: AppColors.success, size: 80),
        const SizedBox(height: 20),
        Text(t.newPassword,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(t.verified,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 32),
        TextField(
          controller: _newPassCtrl,
          obscureText: true,
          style: TextStyle(color: AppColors.text),
          decoration: _inputDecor(t.newPasswordHint, Icons.lock),
          onSubmitted: (_) => _resetPassword(t),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : () => _resetPassword(t),
          style: _btnStyle(),
          child: _loading
              ? _spinner()
              : Text(t.passwordUpdated.split('!').first,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.card,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _spinner() => const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
}
