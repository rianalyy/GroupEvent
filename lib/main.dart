import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/routes/app_routes.dart';
import 'core/constants/app_colors.dart';
import 'services/database_service.dart';
import 'services/session_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR');

  await NotificationService.init();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final sessionUser = await DatabaseService.getSessionUser();
  if (sessionUser != null) SessionService.setUser(sessionUser);

  runApp(ProviderScope(
    child: GroupEventApp(
      startRoute: sessionUser != null ? AppRoutes.home : AppRoutes.welcome,
    ),
  ));
}

class GroupEventApp extends StatelessWidget {
  final String startRoute;
  const GroupEventApp({super.key, required this.startRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GroupEvent',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      initialRoute: startRoute,
      routes: AppRoutes.routes,
    );
  }
}
