import 'package:flutter/material.dart';
import '../../views/welcome/welcome_view.dart';
import '../../views/auth/login_view.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';

  static Map<String, WidgetBuilder> routes = {
    welcome: (context) => const WelcomeView(),
    login: (context) => const LoginView(),
  };
}