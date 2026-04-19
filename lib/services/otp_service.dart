import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

class OtpService {
  OtpService._();

  static const _apiKey      = 're_XUFjNPNS_66jFT5Kydfd2wmpeXWi8a52W';
  static const _fromEmail   = 'GroupEvent <onboarding@resend.dev>';
  static const _fromDomain  = 'resend.dev';

  static String _generate() {
    final rand = Random.secure();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  static Future<({bool sent, String? error})> sendOtp(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed)) {
      return (sent: false, error: 'Adresse email invalide.');
    }

    final otp    = _generate();
    final expiry = DateTime.now().add(const Duration(minutes: 10));
    await SecureStorageService.saveOtp(trimmed, otp, expiry);

    try {
      final resp = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type':  'application/json',
        },
        body: jsonEncode({
          'from':    _fromEmail,
          'to':      [trimmed],
          'subject': 'GroupEvent — Votre code de vérification',
          'html':    _buildHtml(otp),
        }),
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return (sent: true, error: null);
      }

      final body = jsonDecode(resp.body);
      final msg  = body['message'] ?? 'Erreur inconnue (${resp.statusCode})';
      return (sent: false, error: 'Erreur envoi email : $msg');
    } catch (e) {
      return (sent: false, error: 'Connexion impossible. Vérifiez votre réseau.');
    }
  }

  static String _buildHtml(String otp) => '''
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background-color:#0f0020;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 20px;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0"
        style="background:#1e0040;border-radius:20px;padding:40px;border:1px solid rgba(168,85,247,0.4);">
        <tr><td align="center" style="padding-bottom:8px;">
          <span style="font-size:28px;font-weight:bold;color:#a855f7;letter-spacing:2px;">GroupEvent</span>
        </td></tr>
        <tr><td align="center" style="padding-bottom:32px;">
          <span style="color:#ffffff80;font-size:14px;">Vérification de votre identité</span>
        </td></tr>
        <tr><td align="center">
          <table width="100%" cellpadding="0" cellspacing="0"
            style="background:rgba(168,85,247,0.12);border:2px solid #a855f7;border-radius:16px;padding:28px;">
            <tr><td align="center">
              <p style="color:#ffffff80;font-size:13px;margin:0 0 12px;">Votre code de vérification :</p>
              <span style="font-size:48px;font-weight:bold;letter-spacing:16px;color:#ffffff;
                font-family:monospace;">$otp</span>
            </td></tr>
          </table>
        </td></tr>
        <tr><td align="center" style="padding-top:24px;">
          <p style="color:#ffffff60;font-size:13px;margin:0;">
            Ce code expire dans <strong style="color:#ffffff;">10 minutes</strong>.
          </p>
          <p style="color:#ffffff40;font-size:12px;margin:8px 0 0;">
            Si vous n'avez pas demandé ce code, ignorez cet email.
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>''';

  static Future<bool> verify(String email, String code) =>
      SecureStorageService.verifyOtp(email.trim().toLowerCase(), code);

  static Future<void> clear(String email) =>
      SecureStorageService.clearOtp(email.trim().toLowerCase());
}
