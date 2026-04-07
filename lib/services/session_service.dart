import '../models/user_model.dart';

class SessionService {
  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;

  static bool get isLoggedIn => _currentUser != null;

  static void setUser(UserModel user) {
    _currentUser = user;
  }

  static void clear() {
    _currentUser = null;
  }
}
