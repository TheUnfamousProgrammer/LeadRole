import 'package:flutter/material.dart';
import '../../shared/colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "We'll add real content later. By proceeding, you agree to responsible use. "
          "No harassment, no unauthorized likeness, no illegal content.",
          style: TextStyle(height: 1.4),
        ),
      ),
    );
  }
}
