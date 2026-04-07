import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  InputDecoration _inputDecoration(String hint, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.10),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.secondaryLight, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white70, size: 20),
                  onPressed: () {
                    authNotifier.resetForm();
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 16),

                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/logo.png',
                          width: 80, height: 80, fit: BoxFit.contain),
                      const SizedBox(height: 16),
                      const Text(
                        'Bon retour !',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Connectez-vous à GroupEvent',
                        style:
                            TextStyle(fontSize: 14, color: Colors.white54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                const Text('Email',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: AppColors.white),
                  onChanged: authNotifier.setEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                      'exemple@email.com', Icons.email_outlined),
                ),

                const SizedBox(height: 18),

                const Text('Mot de passe',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: AppColors.white),
                  onChanged: authNotifier.setPassword,
                  obscureText: authState.obscurePassword,
                  decoration: _inputDecoration(
                    'Votre mot de passe',
                    Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        authState.obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: authNotifier.toggleObscurePassword,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (authState.status == AuthStatus.error)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.errorMessage,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: authState.status == AuthStatus.loading
                        ? const LinearGradient(
                            colors: [Colors.grey, Colors.grey])
                        : AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: authState.status == AuthStatus.loading
                        ? null
                        : () async {
                            final success = await authNotifier.login();
                            if (success && context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.home,
                                (route) => false,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: authState.status == AuthStatus.loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      authNotifier.resetForm();
                      Navigator.pushReplacementNamed(
                          context, AppRoutes.register);
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Pas encore de compte ? ",
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "S'inscrire",
                            style: TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
