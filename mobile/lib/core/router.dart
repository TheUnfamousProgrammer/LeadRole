import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:leadrole/features/auth/auth_email_password_screen.dart';
import 'package:leadrole/features/dashboard/dashboard_screen.dart';
import 'package:leadrole/features/jobs/ui/job_status_screen.dart';
import 'package:leadrole/features/jobs/ui/wizard/narration_step.dart';
import 'package:leadrole/features/jobs/ui/wizard/review_step.dart';
import 'package:leadrole/features/jobs/ui/wizard/scene_step.dart';
import 'package:leadrole/features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/terms/terms_screen.dart';
import '../features/persona/persona_form_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_controller.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/terms',
      name: 'terms',
      builder: (_, __) => const TermsScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (_, __) => const AuthEmailPasswordScreen(),
    ),
    GoRoute(
      path: '/persona',
      name: 'persona',
      builder: (context, state) {
        final container = ProviderScope.containerOf(context, listen: false);
        final auth = container.read(authProvider);
        if (auth.user == null) return const AuthEmailPasswordScreen();
        return PersonaFormScreen();
      },
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) {
        final container = ProviderScope.containerOf(context, listen: false);
        final auth = container.read(authProvider);
        if (auth.user == null) return const AuthEmailPasswordScreen();
        return DashboardScreen();
      },
    ),
    GoRoute(path: '/produce', builder: (c, s) => const SceneStepScreen()),
    GoRoute(
      path: '/wizard/narration',
      builder: (c, s) => const NarrationStepScreen(),
    ),
    GoRoute(
      path: '/wizard/review',
      builder: (c, s) => const ReviewStepScreen(),
    ),
    GoRoute(
      path: '/jobs/:id',
      builder: (c, s) => JobStatusScreen(jobId: s.pathParameters['id']!),
    ),
  ],
);
