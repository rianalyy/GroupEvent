import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _RegisterBody(),
    );
  }
}

class _RegisterBody extends StatelessWidget {
  const _RegisterBody();

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Consumer<AuthViewModel>(
              builder: (context, vm, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Column(
                        children: [
                          Image.asset('assets/logo.png', width: 80, height: 80, fit: BoxFit.contain),
                          const SizedBox(height: 16),
                          const Text(
                            'Créer un compte',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Rejoignez GroupEvent dès maintenant',
                            style: TextStyle(fontSize: 14, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    const Text('Nom', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(color: AppColors.white),
                      onChanged: vm.setName,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration('Votre nom', Icons.person_outline_rounded),
                    ),

                    const SizedBox(height: 18),

                    const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(color: AppColors.white),
                      onChanged: vm.setEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('exemple@email.com', Icons.email_outlined),
                    ),

                    const SizedBox(height: 18),

                    const Text('Mot de passe', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(color: AppColors.white),
                      onChanged: vm.setPassword,
                      obscureText: vm.obscurePassword,
                      decoration: _inputDecoration(
                        '6 caractères minimum',
                        Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            vm.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: vm.toggleObscurePassword,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text('Confirmer le mot de passe', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(color: AppColors.white),
                      onChanged: vm.setConfirmPassword,
                      obscureText: vm.obscureConfirm,
                      decoration: _inputDecoration(
                        'Répétez votre mot de passe',
                        Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            vm.obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: vm.toggleObscureConfirm,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (vm.status == AuthStatus.error)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vm.errorMessage,
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 28),

                    // Bouton S'inscrire
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: vm.status == AuthStatus.loading
                            ? const LinearGradient(colors: [Colors.grey, Colors.grey])
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
                        onPressed: vm.status == AuthStatus.loading
                            ? null
                            : () async {
                                final success = await vm.register();
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
                        child: vm.status == AuthStatus.loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                "Créer mon compte",
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
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        child: RichText(
                          text: const TextSpan(
                            text: "Déjà un compte ? ",
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Se connecter',
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

                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
