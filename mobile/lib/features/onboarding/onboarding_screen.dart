import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gif/gif.dart';
import 'package:go_router/go_router.dart';

import '../../shared/colors.dart';
import '../../core/widgets/curved_neon_header.dart';
import '../../core/widgets/neon_glow.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accepted = ref.watch(termsAcceptedProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          CurvedNeonHeader(
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'logo',
                        child: Gif(
                          image: AssetImage('assets/images/logo_animated.gif'),
                          width: 400,
                          autostart: Autostart.once,
                          duration: const Duration(seconds: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: accepted,
                        activeColor: AppColors.neon,
                        onChanged: (v) =>
                            ref.read(termsAcceptedProvider.notifier).state =
                                v ?? false,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.pushNamed('terms'),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontFamily: 'Montserrat',
                                fontSize: 12.5,
                              ),
                              children: const [
                                TextSpan(text: "I agree to the "),
                                TextSpan(
                                  text: "Terms & Conditions",
                                  style: TextStyle(
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: accepted
                          ? () => context.goNamed('auth')
                          : null,
                      child: const Text("Get Started"),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "No spam. No drama. Pure creative magic.",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
