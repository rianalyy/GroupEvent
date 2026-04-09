import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import 'event_viewmodel.dart';

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final AuthStatus status;
  final String errorMessage;
  final bool obscurePassword;
  final bool obscureConfirm;

  const AuthState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.status = AuthStatus.idle,
    this.errorMessage = '',
    this.obscurePassword = true,
    this.obscureConfirm = true,
  });

  AuthState copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    AuthStatus? status,
    String? errorMessage,
    bool? obscurePassword,
    bool? obscureConfirm,
  }) {
    return AuthState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirm: obscureConfirm ?? this.obscureConfirm,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void setName(String v) => state = state.copyWith(name: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setPassword(String v) => state = state.copyWith(password: v);
  void setConfirmPassword(String v) => state = state.copyWith(confirmPassword: v);

  void toggleObscurePassword() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);
  void toggleObscureConfirm() =>
      state = state.copyWith(obscureConfirm: !state.obscureConfirm);

  void resetForm() => state = const AuthState();

  bool _isValidEmail(String e) =>
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(e.trim());

  Future<bool> register() async {
    final trimmedName = state.name.trim();
    final trimmedEmail = state.email.trim();

    if (trimmedName.isEmpty) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Veuillez entrer votre nom.');
      return false;
    }
    if (trimmedEmail.isEmpty || !_isValidEmail(trimmedEmail)) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Adresse email invalide.');
      return false;
    }
    if (state.password.length < 6) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Le mot de passe doit contenir au moins 6 caractères.');
      return false;
    }
    if (state.password != state.confirmPassword) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Les mots de passe ne correspondent pas.');
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: '');
    final user = await DatabaseService.register(
      name: trimmedName,
      email: trimmedEmail,
      password: state.password,
    );
    if (user == null) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: 'Cet email est déjà utilisé.');
      return false;
    }

    await DatabaseService.saveSession(user.id!);
    SessionService.setUser(user);

    ref.read(eventProvider.notifier).loadEvents();

    state = state.copyWith(status: AuthStatus.success);
    return true;
  }

  Future<bool> login() async {
    final trimmedEmail = state.email.trim();

    if (trimmedEmail.isEmpty || !_isValidEmail(trimmedEmail)) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Adresse email invalide.');
      return false;
    }
    if (state.password.isEmpty) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Veuillez entrer votre mot de passe.');
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: '');
    final user = await DatabaseService.login(
      email: trimmedEmail,
      password: state.password,
    );
    if (user == null) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Email ou mot de passe incorrect.');
      return false;
    }

    await DatabaseService.saveSession(user.id!);
    SessionService.setUser(user);

    ref.read(eventProvider.notifier).resetState();
    ref.read(eventProvider.notifier).loadEvents();

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

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
