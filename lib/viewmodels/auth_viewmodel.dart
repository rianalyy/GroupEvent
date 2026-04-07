import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../models/user_model.dart';

enum AuthStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';

  AuthStatus status = AuthStatus.idle;
  String errorMessage = '';
  bool obscurePassword = true;
  bool obscureConfirm = true;

  void setName(String v) { name = v; notifyListeners(); }
  void setEmail(String v) { email = v; notifyListeners(); }
  void setPassword(String v) { password = v; notifyListeners(); }
  void setConfirmPassword(String v) { confirmPassword = v; notifyListeners(); }

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    obscureConfirm = !obscureConfirm;
    notifyListeners();
  }

  void _setError(String msg) {
    errorMessage = msg;
    status = AuthStatus.error;
    notifyListeners();
  }

  void _setLoading() {
    errorMessage = '';
    status = AuthStatus.loading;
    notifyListeners();
  }

  void _setSuccess() {
    status = AuthStatus.success;
    notifyListeners();
  }

  void reset() {
    name = '';
    email = '';
    password = '';
    confirmPassword = '';
    errorMessage = '';
    status = AuthStatus.idle;
    notifyListeners();
  }


  bool _isValidEmail(String e) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(e.trim());
  }


  Future<bool> register() async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.isEmpty) {
      _setError('Veuillez entrer votre nom.');
      return false;
    }
    if (trimmedEmail.isEmpty || !_isValidEmail(trimmedEmail)) {
      _setError('Adresse email invalide.');
      return false;
    }
    if (password.length < 6) {
      _setError('Le mot de passe doit contenir au moins 6 caractères.');
      return false;
    }
    if (password != confirmPassword) {
      _setError('Les mots de passe ne correspondent pas.');
      return false;
    }

    _setLoading();

    final user = await DatabaseService.register(
      name: trimmedName,
      email: trimmedEmail,
      password: password,
    );

    if (user == null) {
      _setError('Cet email est déjà utilisé.');
      return false;
    }

    await DatabaseService.saveSession(user.id!);
    SessionService.setUser(user);

    _setSuccess();
    return true;
  }

  Future<bool> login() async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty || !_isValidEmail(trimmedEmail)) {
      _setError('Adresse email invalide.');
      return false;
    }
    if (password.isEmpty) {
      _setError('Veuillez entrer votre mot de passe.');
      return false;
    }

    _setLoading();

    final user = await DatabaseService.login(
      email: trimmedEmail,
      password: password,
    );

    if (user == null) {
      _setError('Email ou mot de passe incorrect.');
      return false;
    }


    await DatabaseService.saveSession(user.id!);
    SessionService.setUser(user);

    _setSuccess();
    return true;
  }

  Future<void> logout() async {
    await DatabaseService.clearSession();
    SessionService.clear();
    reset();
  }
}
