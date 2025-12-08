// lib/screens/contact_us_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

/// =======================================================
///  LAUNCH SERVICES (call / email / whatsapp / maps)
/// =======================================================
class LaunchServices {
  final BuildContext context;
  LaunchServices(this.context);

  void _showError(String service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('unable_open', namedArgs: {'service': service})),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> launchCall(String phone) async {
    final Uri call = Uri(scheme: "tel", path: phone);
    try {
      if (!await launchUrl(call, mode: LaunchMode.externalApplication)) {
        _showError(tr('dialer'));
      }
    } catch (_) {
      _showError(tr('dialer'));
    }
  }

  Future<void> launchEmail(String to, {String subject = '', String body = ''}) async {
    final Uri email = Uri(
      scheme: "mailto",
      path: to,
      query: Uri(queryParameters: {
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      }).query,
    );
    try {
      if (!await launchUrl(email, mode: LaunchMode.externalApplication)) {
        _showError(tr('email'));
      }
    } catch (_) {
      _showError(tr('email'));
    }
  }

  Future<void> launchWhatsapp(String phone, {String text = ''}) async {
    final Uri wa = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(text)}");
    try {
      if (!await launchUrl(wa, mode: LaunchMode.externalApplication)) {
        _showError(tr('whatsapp'));
      }
    } catch (_) {
      _showError(tr('whatsapp'));
    }
  }

  Future<void> launchMaps(String query) async {
    final Uri map = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}");
    try {
      if (!await launchUrl(map, mode: LaunchMode.externalApplication)) {
        _showError(tr('maps'));
      }
    } catch (_) {
      _showError(tr('maps'));
    }
  }
}

/// =======================================================
///  CONTACT US PAGE
/// =======================================================
class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final LaunchServices launchServices;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final msgCtrl = TextEditingController();

  // Example contact values (replace with real ones)
  final String supportPhone = '+919999999999';
  final String supportWhatsapp = '918767258243'; // WhatsApp requires country code without '+'
  final String supportEmail = 'abccompany@gmail.com';
  final String supportLocationQuery = 'Qutb Minar, Delhi';

  @override
  void initState() {
    super.initState();
    launchServices = LaunchServices(context);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    msgCtrl.dispose();
    super.dispose();
  }

  // --- SUBMIT LOGIC (Theme Compliant Dialog) ---
  void _submitForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(tr('message_sent'), style: theme.textTheme.titleMedium)),
            ],
          ),
          content: Text(tr('we_will_respond'), style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dCtx);
                nameCtrl.clear();
                emailCtrl.clear();
                msgCtrl.clear();
              },
              child: Text("OK", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
  }

  // --- HELPER WIDGETS (Theme Compliant) ---
  Widget _quickAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 152,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colorScheme.onSurface.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.1), width: 0.5),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, radius: 20, child: Icon(icon, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(tr('tap_to_open'), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController ctrl,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        fillColor: theme.inputDecorationTheme.fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      style: theme.textTheme.bodyLarge,
    );
  }

  Widget _socialButton(IconData icon, String url, Color color) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(40),
      child: CircleAvatar(radius: 26, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 22)),
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = MediaQuery.of(context).size.width > 760;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        title: Text(tr('app_title'), style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: tr('call_support'),
            onPressed: () => launchServices.launchCall(supportPhone),
            icon: Icon(Icons.phone, color: colorScheme.onPrimary),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card with friendly intro
              Card(
                color: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(Icons.support_agent, color: colorScheme.secondary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('need_help'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(tr('contact_subtitle'), style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            Chip(label: Text(tr('support_24h')), backgroundColor: colorScheme.surfaceVariant),
                            Chip(label: Text(tr('fast_replies')), backgroundColor: colorScheme.secondary.withOpacity(0.2)),
                          ]),
                        ]),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(tr('quick_actions'), style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onBackground, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _quickAction(
                    label: tr('call'),
                    icon: Icons.phone_rounded,
                    color: colorScheme.primary,
                    onTap: () => launchServices.launchCall(supportPhone),
                  ),
                  _quickAction(
                    label: tr('whatsapp'),
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF25D366),
                    onTap: () => launchServices.launchWhatsapp(supportWhatsapp, text: tr('hello_support')),
                  ),
                  _quickAction(
                    label: tr('email'),
                    icon: Icons.email_outlined,
                    color: Colors.blue.shade700,
                    onTap: () => launchServices.launchEmail(supportEmail, subject: tr('support_request'), body: ''),
                  ),
                  _quickAction(
                    label: tr('location'),
                    icon: Icons.location_on_outlined,
                    color: colorScheme.error,
                    onTap: () => launchServices.launchMaps(supportLocationQuery),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              Text(tr('write_to_us'), style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onBackground, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),

              Card(
                color: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _inputField(
                          hint: tr('full_name_hint'),
                          icon: Icons.person_outline,
                          ctrl: nameCtrl,
                          validator: (String? v) {
                            if (v == null || v.trim().length < 2) return tr('enter_name');
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _inputField(
                          hint: tr('email_address_hint'),
                          icon: Icons.email_outlined,
                          ctrl: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (String? v) {
                            if (v == null || !v.contains("@")) return tr('enter_valid_email');
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _inputField(
                          hint: tr('your_message_hint'),
                          icon: Icons.message_outlined,
                          ctrl: msgCtrl,
                          maxLines: 5,
                          validator: (String? v) {
                            if (v == null || v.trim().length < 8) return tr('message_too_short');
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                            ),
                            child: Text(tr('send_message'), style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Center(child: Text(tr('follow_us'), style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onBackground, fontWeight: FontWeight.w800))),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _socialButton(Icons.facebook, 'https://facebook.com', Colors.blue.shade700),
                const SizedBox(width: 18),
                _socialButton(Icons.camera_alt, 'https://instagram.com', Colors.pink.shade700),
                const SizedBox(width: 18),
                _socialButton(Icons.play_circle_fill, 'https://youtube.com', Colors.red.shade700),
              ]),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
