import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../home/main_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();

  String _selectedQuestion = AuthService.securityQuestions.first;
  bool _loading = false;
  bool _isRegister = false;

  Future<void> _submit() async {
    final t = AppL.of(context);

    if (_isRegister) {
      if (_userCtrl.text.trim().isEmpty) {
        _showSnack(t.usernameRequired, AppColors.error);
        return;
      }
      if (_answerCtrl.text.trim().isEmpty) {
        _showSnack(t.securityAnswerRequired, AppColors.error);
        return;
      }
    }

    if (_emailCtrl.text.trim().isEmpty) {
      _showSnack(t.emailRequired, AppColors.error);
      return;
    }
    if (_passCtrl.text.length < 6) {
      _showSnack(t.passwordTooShort, AppColors.error);
      return;
    }
    if (!_emailCtrl.text.contains('@') || !_emailCtrl.text.contains('.')) {
      _showSnack(t.invalidEmail, AppColors.error);
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isRegister) {
        final prefs = await SharedPreferences.getInstance();
        final langCode = prefs.getString('language') ??
            Localizations.localeOf(context).languageCode;

        final res = await AuthService.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          username: _userCtrl.text.trim(),
          securityQuestion: _selectedQuestion,
          securityAnswer: _answerCtrl.text.trim(),
          languageCode: langCode,
        );
        if (res == null) throw Exception('Register failed');

        if (res.user != null) {
          if (res.session == null) {
            final loginRes = await AuthService.signIn(
              email: _emailCtrl.text.trim(),
              password: _passCtrl.text.trim(),
            );
            if (loginRes?.session == null) {
              throw Exception('Session failed');
            }
          }
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        } else {
          throw Exception('Register failed');
        }
      } else {
        final res = await AuthService.signIn(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        if (res == null || res.session == null) {
          throw Exception('Login failed');
        }
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      _showSnack('${t.error}: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/zyrova-logo.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text('Z',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isRegister ? t.welcomeRegister : t.welcomeBack,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(t.tagline,
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                if (_isRegister) ...[
                  TextField(
                    controller: _userCtrl,
                    style: TextStyle(color: AppColors.text),
                    decoration: _inputDecor(t.usernameHint, Icons.person),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: AppColors.text),
                  decoration: _inputDecor(t.email, Icons.email),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: TextStyle(color: AppColors.text),
                  decoration: _inputDecor(t.passwordHint, Icons.lock),
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedQuestion,
                        isExpanded: true,
                        dropdownColor: AppColors.card,
                        icon: Icon(Icons.arrow_drop_down,
                            color: AppColors.primary),
                        style: TextStyle(color: AppColors.text),
                        items: AuthService.securityQuestions
                            .map((q) => DropdownMenuItem(
                                  value: q,
                                  child: Text(q,
                                      style: TextStyle(
                                          color: AppColors.text,
                                          fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedQuestion = v);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answerCtrl,
                    style: TextStyle(color: AppColors.text),
                    decoration: _inputDecor(
                        t.securityAnswerHint, Icons.shield_outlined),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.securityQuestionWarning,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
                if (!_isRegister)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        t.forgotPassword,
                        style: TextStyle(
                            color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ),
                SizedBox(height: _isRegister ? 24 : 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isRegister ? t.register : t.login,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() => _isRegister = !_isRegister);
                  },
                  child: Text(
                    _isRegister ? t.alreadyHaveAccount : t.dontHaveAccount,
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
