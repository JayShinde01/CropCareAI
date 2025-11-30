import 'package:demo/screens/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  String? selectedRole = "farmer";

  final roles = [
    {"key": "agronomist", "label": "Agronomist or Crop advisor"},
    {"key": "farmer", "label": "Farmer"},
    {"key": "home_grower", "label": "Home grower or Professional gardener"},
  ];

  void _onNext() {
    debugPrint("Selected role: $selectedRole");
    if(selectedRole == "farmer"){
      Navigator.push(context, 
      MaterialPageRoute(builder: (context) => LandingScreen(),)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.eco, color: Color(0xFF64DD17)),
            SizedBox(width: 6),
            Text(
              "CropCareAI",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Which of the following best describes you?",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ...roles.map((role) {
              return RadioListTile(
                value: role["key"],
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value.toString();
                  });
                },
                activeColor: const Color(0xFF64DD17),
                title: Text(
                  role["label"]!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              );
            }),

            const Spacer(),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF64DD17),
        onPressed: _onNext,
        child: const Icon(Icons.arrow_forward, color: Colors.black),
      ),
    );
  }
}
