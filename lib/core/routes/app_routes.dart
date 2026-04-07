import 'package:flutter/material.dart';
import '../../views/welcome/welcome_view.dart';
import '../../views/auth/login_view.dart';
import '../../views/auth/register_view.dart';
import '../../views/home/home_view.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    welcome:  (_) => const WelcomeView(),
    login:    (_) => const LoginView(),
    register: (_) => const RegisterView(),
    home:     (_) => const HomeView(),
  };
}
