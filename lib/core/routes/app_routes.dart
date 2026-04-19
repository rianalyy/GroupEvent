import 'package:flutter/material.dart';
import '../../views/welcome/welcome_view.dart';
import '../../views/auth/login_view.dart';
import '../../views/auth/register_view.dart';
import '../../views/auth/otp_view.dart';
import '../../views/home/home_view.dart';
import '../../views/home/event_detail_view.dart';
import '../../views/map/map_view.dart';

class AppRoutes {
  static const String welcome     = '/';
  static const String login       = '/login';
  static const String register    = '/register';
  static const String otp         = '/otp';
  static const String home        = '/home';
  static const String eventDetail = '/event-detail';
  static const String map         = '/map';

  static Map<String, WidgetBuilder> routes = {
    welcome:     (_) => const WelcomeView(),
    login:       (_) => const LoginView(),
    register:    (_) => const RegisterView(),
    otp:         (_) => const OtpView(),
    home:        (_) => const HomeView(),
    eventDetail: (_) => const EventDetailView(),
    map:         (_) => const MapView(),
  };
}
