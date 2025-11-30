// lib/screens/landing_screen.dart
import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  // Small helper to scale font sizes for smaller/larger devices
  double _scale(BuildContext c, double v) => v * MediaQuery.of(c).textScaleFactor;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF74C043);
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 600;

    return Scaffold(
      // Use a slightly warm dark background for better contrast
      backgroundColor: const Color(0xFF0B0B0B),
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative arc at top (subtle)
            Positioned.fill(child: CustomPaint(painter: _ArcPainter())),

            // Top-right — small drone icon (tappable to show info)
            Positioned(
              top: 12,
              right: 12,
              child: Semantics(
                label: 'Drone overview. Tap for more info',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.airplanemode_active_rounded, size: 36, color: Colors.white70),
                  onPressed: () => _showHelpDialog(context),
                ),
              ),
            ),

            // Main centered content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Friendly headline
                    Text(
                      'Welcome to CropAI',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: _scale(context, isWide ? 28 : 22),
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                      semanticsLabel: 'Welcome to Crop AI',
                    ),

                    const SizedBox(height: 10),

                    // Simple descriptive subtext
                    Text(
                      'Smart farming help for your fields — fast, simple.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontSize: _scale(context, 14),
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 22),

                    // Primary CTA — big, friendly
                    SizedBox(
                      width: isWide ? 360 : double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined, color: Colors.black),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Text('Take a Photo of Crop', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 4,
                        ),
                        onPressed: () {
                          // navigate to camera/identify flow
                          // for now go to signup or show placeholder
                          Navigator.pushNamed(context, '/signup');
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Secondary action row (3 clear options)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _smallAction(
                          context,
                          icon: Icons.search,
                          label: 'Ask Advice',
                          sub: 'Get simple tips',
                          onTap: () {
                            // open advice flow
                            _showSnack(context, 'Advice tapped');
                          },
                        ),
                        const SizedBox(width: 12),
                        _smallAction(
                          context,
                          icon: Icons.map,
                          label: 'Scan Field',
                          sub: 'Check whole field',
                          onTap: () {
                            _showSnack(context, 'Scan field tapped');
                          },
                        ),
                        const SizedBox(width: 12),
                        _smallAction(
                          context,
                          icon: Icons.phone_android,
                          label: 'Manuals',
                          sub: 'Step-by-step guides',
                          onTap: () {
                            _showSnack(context, 'Manuals tapped');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Login / account link (small)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Have an account?',
                          style: TextStyle(color: Colors.white70, fontSize: _scale(context, 14)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          child: Text(
                            'Login',
                            style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: _scale(context, 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom illustration (simple stylized wheat + phone)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomIllustration(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallAction(BuildContext context,
      {required IconData icon, required String label, required String sub, required VoidCallback onTap}) {
    return Expanded(
      child: Semantics(
        button: true,
        label: '$label. $sub',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(icon, size: 26, color: Colors.white),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Small helpful dialog explaining icons in plain language for farmers
  void _showHelpDialog(BuildContext c) {
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('How CropAI helps you', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '• Take a Photo of Crop — point your phone at the plant. The app will identify pests or diseases and give simple steps.\n\n'
          '• Ask Advice — get short tips (how much water, when to spray).\n\n'
          '• Scan Field — check larger areas with maps or drone support.\n\n'
          'If you need help, ask a neighbor or call support from the app.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Got it'),
          )
        ],
      ),
    );
  }

  void _showSnack(BuildContext c, String text) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));
  }
}

// ----------------------
// Bottom stylized illustration (drawn so no external assets required)
// ----------------------
class _BottomIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use a fixed height that looks good on phones
    return SizedBox(
      height: 210,
      child: CustomPaint(
        painter: _WheatPainter(),
        size: Size(MediaQuery.of(context).size.width, 210),
      ),
    );
  }
}

class _WheatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // draw rolling green hills
    final hill1 = Path()
      ..moveTo(0, h * 0.8)
      ..quadraticBezierTo(w * 0.25, h * 0.6, w * 0.5, h * 0.8)
      ..quadraticBezierTo(w * 0.75, h * 1.0, w, h * 0.8)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final hillPaint = Paint()..style = PaintingStyle.fill;
    hillPaint.color = Colors.green.shade700;
    canvas.drawPath(hill1, hillPaint);

    final hill2 = Path()
      ..moveTo(0, h * 0.9)
      ..quadraticBezierTo(w * 0.3, h * 0.75, w * 0.6, h * 0.9)
      ..quadraticBezierTo(w * 0.85, h * 1.0, w, h * 0.9)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final hillPaint2 = Paint()..color = Colors.green.shade600;
    canvas.drawPath(hill2, hillPaint2);

    // stylized wheat stalks
    final stalkPaint = Paint()
      ..color = Colors.amber.shade700
      ..style = PaintingStyle.fill;

    void drawWheat(double x, double stalkHeight) {
      final centerX = x;
      final baseY = h * 0.65;
      // stalk
      canvas.drawRect(Rect.fromLTWH(centerX - 2.5, baseY - stalkHeight, 5, stalkHeight), stalkPaint);
      // leaves / grains (simple ovals)
      final grainPaint = Paint()..color = Colors.amber.shade600;
      for (int i = 0; i < 5; i++) {
        final gy = baseY - stalkHeight + i * (stalkHeight / 5);
        final rx = 14.0;
        canvas.save();
        canvas.translate(centerX, gy);
        canvas.rotate(i.isEven ? -0.4 : 0.4);
        canvas.drawOval(Rect.fromCenter(center: Offset(0, 0), width: rx, height: 18), grainPaint);
        canvas.restore();
      }
    }

    drawWheat(w * 0.12, h * 0.35);
    drawWheat(w * 0.28, h * 0.45);
    drawWheat(w * 0.45, h * 0.5);

    // phone block on right
    final phoneRect = Rect.fromLTWH(w * 0.7, h * 0.55, 72, 110);
    final phonePaint = Paint()..color = const Color(0xFF0F4C75);
    final phoneR = RRect.fromRectAndRadius(phoneRect, const Radius.circular(12));
    canvas.drawRRect(phoneR, phonePaint);

    // screen
    final screenRect = Rect.fromLTWH(w * 0.71, h * 0.575, 68, 90);
    final screenPaint = Paint()..color = const Color(0xFFFFE6C7);
    canvas.drawRect(screenRect, screenPaint);

    // simple leaf inside phone screen
    final leafPaint = Paint()..color = Colors.green.shade600;
    final leafPath = Path()
      ..moveTo(w * 0.71 + 10, h * 0.575 + 45)
      ..quadraticBezierTo(w * 0.8, h * 0.575 + 10, w * 0.71 + 55, h * 0.575 + 45)
      ..quadraticBezierTo(w * 0.8, h * 0.575 + 80, w * 0.71 + 10, h * 0.575 + 45)
      ..close();
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simple arc painter used for the top curve
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade600.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..isAntiAlias = true;
    final w = size.width;
    final path = Path()
      ..moveTo(-w * 0.1, size.height * 0.12)
      ..quadraticBezierTo(w * 0.5, size.height * -0.06, w * 1.1, size.height * 0.12);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
