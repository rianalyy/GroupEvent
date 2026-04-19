import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class RegisterView extends ConsumerWidget {
  const RegisterView({super.key});

  InputDecoration _deco(String hint, IconData icon, {Widget? suffix}) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.white54),
    prefixIcon: Icon(icon, color: Colors.white54, size: 20), suffixIcon: suffix,
    filled: true, fillColor: Colors.white.withOpacity(0.10),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.5)),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth     = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                onPressed: () { notifier.resetForm(); Navigator.pop(context); },
              ),
              const SizedBox(height: 16),
              Center(child: Column(children: [
                Image.asset('assets/logo.png', width: 80, height: 80, fit: BoxFit.contain),
                const SizedBox(height: 16),
                const Text('Créer un compte', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.white)),
                const SizedBox(height: 6),
                const Text('Rejoignez GroupEvent dès maintenant', style: TextStyle(fontSize: 14, color: Colors.white54)),
              ])),
              const SizedBox(height: 32),
              const Text('Nom complet', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(style: const TextStyle(color: AppColors.white), onChanged: notifier.setName,
                  textCapitalization: TextCapitalization.words,
                  decoration: _deco('Votre nom', Icons.person_outline_rounded)),
              const SizedBox(height: 16),
              const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(style: const TextStyle(color: AppColors.white), onChanged: notifier.setEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _deco('exemple@gmail.com', Icons.email_outlined)),
              const SizedBox(height: 4),
              const Text('  Utilisez un email existant (Gmail, Yahoo, etc.)',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 16),
              const Text('Mot de passe', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: AppColors.white), onChanged: notifier.setPassword,
                obscureText: auth.obscurePassword,
                decoration: _deco('Min. 8 car. avec A-Z, a-z, 0-9, !@#...', Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(auth.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white54, size: 20),
                      onPressed: notifier.toggleObscurePassword,
                    )),
              ),
              const SizedBox(height: 6),
              _PasswordStrengthBar(password: auth.password),
              const SizedBox(height: 16),
              const Text('Confirmer le mot de passe', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: AppColors.white), onChanged: notifier.setConfirmPassword,
                obscureText: auth.obscureConfirm,
                decoration: _deco('Répétez votre mot de passe', Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(auth.obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white54, size: 20),
                      onPressed: notifier.toggleObscureConfirm,
                    )),
              ),
              const SizedBox(height: 12),
              if (auth.status == AuthStatus.error)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 18), const SizedBox(width: 8),
                    Expanded(child: Text(auth.errorMessage, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ]),
                ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity, height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: auth.status == AuthStatus.loading
                      ? const LinearGradient(colors: [Colors.grey, Colors.grey]) : AppColors.primaryGradient,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ElevatedButton(
                  onPressed: auth.status == AuthStatus.loading ? null : () async {
                    final ok = await notifier.sendOtpForRegister();
                    if (ok && context.mounted) Navigator.pushNamed(context, AppRoutes.otp);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: auth.status == AuthStatus.loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Créer mon compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: GestureDetector(
                onTap: () { notifier.resetForm(); Navigator.pushReplacementNamed(context, AppRoutes.login); },
                child: RichText(text: const TextSpan(
                  text: 'Déjà un compte ? ', style: TextStyle(color: Colors.white54, fontSize: 14),
                  children: [TextSpan(text: 'Se connecter',
                      style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.w600))],
                )),
              )),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int _score() {
    int s = 0;
    if (password.length >= 8)                                               s++;
    if (password.contains(RegExp(r'[A-Z]')))                                s++;
    if (password.contains(RegExp(r'[a-z]')))                                s++;
    if (password.contains(RegExp(r'[0-9]')))                                s++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\]')))     s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final score = _score();
    final colors = [Colors.red, Colors.orange, Colors.orange, AppColors.warning, AppColors.success];
    final labels = ['Très faible', 'Faible', 'Moyen', 'Fort', 'Très fort'];
    final color  = colors[score == 0 ? 0 : score - 1];
    final label  = labels[score == 0 ? 0 : score - 1];
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: List.generate(5, (i) => Expanded(child: Container(
          height: 4, margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: i < score ? color : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2)),
        )))),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
