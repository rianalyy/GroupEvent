import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';

class OtpView extends ConsumerWidget {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth     = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                onPressed: () { notifier.resetForm(); Navigator.pop(context); },
              ),
              const SizedBox(height: 24),
              Center(child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16)],
                  ),
                  child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                const Text('Vérification email',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.white)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                      SizedBox(width: 6),
                      Text('Code envoyé par email !',
                          style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      'Consultez la boîte mail de\n${auth.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                    ),
                  ]),
                ),
              ])),
              const SizedBox(height: 36),
              const Text('Entrez le code à 6 chiffres',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              _OtpInput(onChanged: notifier.setOtpCode),
              const SizedBox(height: 8),
              const Text('Le code expire dans 10 minutes.',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 16),
              if (auth.status == AuthStatus.error)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(auth.errorMessage,
                        style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ]),
                ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity, height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: auth.status == AuthStatus.loading
                      ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                      : AppColors.primaryGradient,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ElevatedButton(
                  onPressed: auth.status == AuthStatus.loading ? null : () async {
                    final ok = await notifier.verifyOtp();
                    if (ok && context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: auth.status == AuthStatus.loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Vérifier',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: auth.status == AuthStatus.loading ? null : () async {
                    if (auth.isRegisterFlow) await notifier.sendOtpForRegister();
                    else await notifier.sendOtpForLogin();
                  },
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.secondaryLight, size: 18),
                  label: const Text('Renvoyer le code',
                      style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.w500)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OtpInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _OtpInput({required this.onChanged});
  @override State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> {
  final List<TextEditingController> _c = List.generate(6, (_) => TextEditingController());
  final List<FocusNode>             _n = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final x in _c) x.dispose();
    for (final x in _n) x.dispose();
    super.dispose();
  }

  void _onChange(int i, String v) {
    if (v.length > 1) {
      final d = v.replaceAll(RegExp(r'\D'), '');
      for (var j = 0; j < 6 && j < d.length; j++) _c[j].text = d[j];
      widget.onChanged(_c.map((x) => x.text).join());
      if (d.length >= 6) FocusScope.of(context).unfocus();
      return;
    }
    if (v.isNotEmpty && i < 5) FocusScope.of(context).requestFocus(_n[i + 1]);
    if (v.isEmpty && i > 0)    FocusScope.of(context).requestFocus(_n[i - 1]);
    widget.onChanged(_c.map((x) => x.text).join());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) => SizedBox(
        width: 46,
        child: TextField(
          controller: _c[i], focusNode: _n[i],
          textAlign: TextAlign.center, keyboardType: TextInputType.number,
          maxLength: i == 0 ? 6 : 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '', filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.secondaryLight, width: 2)),
          ),
          onChanged: (v) => _onChange(i, v),
        ),
      )),
    );
  }
}
