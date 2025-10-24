import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leadrole/features/auth/auth_repository.dart';
import 'package:leadrole/shared/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../auth/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserState();
  }

  Future<void> _checkUserState() async {
    final authController = ref.read(authProvider.notifier);
    final repo = ref.read(authRepositoryProvider);

    try {
      // Fetch userId from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        if (mounted) {
          context.pushNamed('onboarding');
        }
      } else {
        // Fetch user details and store in state
        final user = await repo.getUser(userId);
        if (user != null) {
          authController.state = authController.state.copyWith(user: user);
        }

        // Check if the user has a persona
        final hasPersona = await authController.ref
            .read(authRepositoryProvider)
            .hasPersona(userId);

        if (hasPersona) {
          // Persona exists, navigate to dashboard
          if (mounted) {
            context.pushNamed('dashboard');
          }
        } else {
          // Persona does not exist, navigate to persona creation screen
          if (mounted) {
            context.pushNamed('persona');
          }
        }
      }
    } catch (e) {
      // Handle errors
      debugPrint("Error in SplashScreen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppColors.neon,
              shadowColor: AppColors.neonSoft.withOpacity(0.6),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/images/icon.png', width: 200),
              ),
            ),
          ),
          SizedBox(height: 50),
          CupertinoActivityIndicator(radius: 15, color: AppColors.neonSoft),
        ],
      ),
    );
  }
}
