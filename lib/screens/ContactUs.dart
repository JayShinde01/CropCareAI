import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// =======================================================
///  LAUNCH SERVICES
/// =======================================================
class LaunchServices {
  final BuildContext context;
  LaunchServices(this.context);

  void _showError(String service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Unable to open $service"),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> launchCall() async {
    final Uri call = Uri(scheme: "tel", path: "+919999999999");
    try {
      if (!await launchUrl(call, mode: LaunchMode.externalApplication)) {
        _showError("Dialer");
      }
    } catch (_) {
      _showError("Dialer");
    }
  }

  Future<void> launchEmail() async {
    final Uri email = Uri(
      scheme: "mailto",
      path: "abccompany@gmail.com",
      query: "subject=Support&body=Hello",
    );
    try {
      if (!await launchUrl(email, mode: LaunchMode.externalApplication)) {
        _showError("Email");
      }
    } catch (_) {
      _showError("Email");
    }
  }

  Future<void> launchWhatsapp() async {
    final Uri wa = Uri.parse(
        "https://wa.me/918767258243?text=Hello%20Support%20Team");
    try {
      if (!await launchUrl(wa, mode: LaunchMode.externalApplication)) {
        _showError("WhatsApp");
      }
    } catch (_) {
      _showError("WhatsApp");
    }
  }

  Future<void> launchMaps() async {
    const String q = "Qutb Minar, Delhi";
    final Uri map = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$q");
    try {
      if (!await launchUrl(map, mode: LaunchMode.externalApplication)) {
        _showError("Maps");
      }
    } catch (_) {
      _showError("Maps");
    }
  }
}

/// =======================================================
///  CONTACT US PAGE (MODERN DARK UI)
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

  final Color mainGreen = const Color(0xFF00C853);
  final Color cardDark = const Color(0xFF1E1E1E);

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: mainGreen),
              const SizedBox(width: 8),
              const Text("Message Sent!", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "We’ll respond within 24 hours.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                nameCtrl.clear();
                emailCtrl.clear();
                msgCtrl.clear();
              },
              child: Text("OK", style: TextStyle(color: mainGreen)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Support", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Need help?",
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Reach us instantly using any option below.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 25),

            /// -------- Quick Action Buttons --------
            Wrap(
              runSpacing: 12,
              spacing: 12,
              children: [
                _actionButton("Call", Icons.phone, launchServices.launchCall, mainGreen),
                _actionButton("WhatsApp", Icons.chat_bubble, launchServices.launchWhatsapp, const Color(0xFF25D366)),
                _actionButton("Email", Icons.email, launchServices.launchEmail, Colors.blue),
                _actionButton("Location", Icons.location_pin, launchServices.launchMaps, Colors.redAccent),
              ],
            ),

            const SizedBox(height: 35),

            /// -------- Form --------
            Text(
              "Write to us",
              style: TextStyle(
                fontSize: 22,
                color: mainGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _inputField("Full Name", Icons.person, nameCtrl),
                  const SizedBox(height: 15),
                  _inputField("Email Address", Icons.email, emailCtrl,
                      validator: (v) =>
                          (v == null || !v.contains("@")) ? "Enter valid email" : null),
                  const SizedBox(height: 15),
                  _inputField("Your Message", Icons.message, msgCtrl,
                      maxLines: 4,
                      validator: (v) => (v == null || v.length < 5)
                          ? "Message too short"
                          : null),
                  const SizedBox(height: 25),

                  /// Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainGreen,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Send Message",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: Text(
                "Follow us",
                style: TextStyle(
                    color: mainGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialBtn(Icons.facebook, "https://facebook.com", Colors.blue),
                const SizedBox(width: 20),
                _socialBtn(Icons.camera_alt, "https://instagram.com", Colors.pink),
                const SizedBox(width: 20),
                _socialBtn(Icons.play_circle_fill, "https://youtube.com", Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UI WIDGETS =================

  Widget _inputField(
    String hint,
    IconData icon,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: cardDark,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: mainGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _actionButton(
      String name, IconData icon, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(name),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(255),
        foregroundColor: Colors.white,
        minimumSize: const Size(140, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _socialBtn(IconData icon, String url, Color color) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: color,
        child: Icon(icon, size: 28, color: Colors.white),
      ),
    );
  }
}
