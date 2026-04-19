import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../services/secure_storage_service.dart';
import '../services/otp_service.dart';
import 'event_viewmodel.dart';

enum AuthStatus { idle, loading, otpSent, success, error }

class AuthState {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String otpCode;
  final AuthStatus status;
  final String errorMessage;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool isRegisterFlow;

  const AuthState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.otpCode = '',
    this.status = AuthStatus.idle,
    this.errorMessage = '',
    this.obscurePassword = true,
    this.obscureConfirm = true,
    this.isRegisterFlow = false,
  });

  AuthState copyWith({
    String? name, String? email, String? password, String? confirmPassword,
    String? otpCode, AuthStatus? status, String? errorMessage,
    bool? obscurePassword, bool? obscureConfirm, bool? isRegisterFlow,
  }) => AuthState(
    name: name ?? this.name,
    email: email ?? this.email,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    otpCode: otpCode ?? this.otpCode,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
    obscurePassword: obscurePassword ?? this.obscurePassword,
    obscureConfirm: obscureConfirm ?? this.obscureConfirm,
    isRegisterFlow: isRegisterFlow ?? this.isRegisterFlow,
  );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void setName(String v)            => state = state.copyWith(name: v);
  void setEmail(String v)           => state = state.copyWith(email: v);
  void setPassword(String v)        => state = state.copyWith(password: v);
  void setConfirmPassword(String v) => state = state.copyWith(confirmPassword: v);
  void setOtpCode(String v)         => state = state.copyWith(otpCode: v);
  void toggleObscurePassword()      => state = state.copyWith(obscurePassword: !state.obscurePassword);
  void toggleObscureConfirm()       => state = state.copyWith(obscureConfirm: !state.obscureConfirm);
  void resetForm()                  => state = const AuthState();

  bool _isValidEmail(String e) =>
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(e.trim());

  bool _isStrongPassword(String p) {
    return p.length >= 8 &&
        p.contains(RegExp(r'[A-Z]')) &&
        p.contains(RegExp(r'[a-z]')) &&
        p.contains(RegExp(r'[0-9]')) &&
        p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\]'));
  }

  String _passwordHint(String p) {
    if (p.length < 8)                                              return 'Minimum 8 caractères.';
    if (!p.contains(RegExp(r'[A-Z]')))                            return 'Ajoutez une majuscule.';
    if (!p.contains(RegExp(r'[a-z]')))                            return 'Ajoutez une minuscule.';
    if (!p.contains(RegExp(r'[0-9]')))                            return 'Ajoutez un chiffre.';
    if (!p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\]'))) return 'Ajoutez un caractère spécial (!@#\$...).';
    return '';
  }

  void _setError(String msg) =>
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);

  Future<bool> sendOtpForRegister() async {
    final name  = state.name.trim();
    final email = state.email.trim();
    if (name.isEmpty)                    { _setError('Veuillez entrer votre nom.'); return false; }
    if (!_isValidEmail(email))           { _setError('Email invalide.'); return false; }
    if (!_isStrongPassword(state.password)) { _setError(_passwordHint(state.password)); return false; }
    if (state.password != state.confirmPassword) { _setError('Les mots de passe ne correspondent pas.'); return false; }

    final existing = await DatabaseService.getUserByEmail(email);
    if (existing != null) { _setError('Cet email est déjà utilisé.'); return false; }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: '', isRegisterFlow: true);
    final result = await OtpService.sendOtp(email);
    if (!result.sent) { _setError(result.error ?? 'Erreur envoi OTP.'); return false; }

    state = state.copyWith(status: AuthStatus.otpSent);
    return true;
  }

  Future<bool> sendOtpForLogin() async {
    final email = state.email.trim();
    if (!_isValidEmail(email))  { _setError('Email invalide.'); return false; }
    if (state.password.isEmpty) { _setError('Mot de passe requis.'); return false; }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: '', isRegisterFlow: false);
    final user = await DatabaseService.login(email: email, password: state.password);
    if (user == null) { _setError('Email ou mot de passe incorrect.'); return false; }

    final result = await OtpService.sendOtp(email);
    if (!result.sent) { _setError(result.error ?? 'Erreur envoi OTP.'); return false; }

    state = state.copyWith(status: AuthStatus.otpSent);
    return true;
  }

  Future<bool> verifyOtp() async {
    final email = state.email.trim();
    state = state.copyWith(status: AuthStatus.loading, errorMessage: '');
    final ok = await OtpService.verify(email, state.otpCode);
    if (!ok) { _setError('Code incorrect ou expiré.'); return false; }
    await OtpService.clear(email);

    if (state.isRegisterFlow) {
      final user = await DatabaseService.register(
          name: state.name.trim(), email: email, password: state.password);
      if (user == null) { _setError('Erreur lors de la création du compte.'); return false; }
      await SecureStorageService.savePassword(email, user.password);
      await DatabaseService.saveSession(user.id!);
      SessionService.setUser(user);
      ref.read(eventProvider.notifier).loadEvents();
    } else {
      final user = await DatabaseService.login(email: email, password: state.password);
      if (user == null) { _setError('Erreur de connexion.'); return false; }
      await DatabaseService.saveSession(user.id!);
      SessionService.setUser(user);
      ref.read(eventProvider.notifier).resetState();
      ref.read(eventProvider.notifier).loadEvents();
    }
    state = state.copyWith(status: AuthStatus.success);
    return true;
  }

  Future<void> logout() async {
    await DatabaseService.clearSession();
    SessionService.clear();
    ref.read(eventProvider.notifier).resetState();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
