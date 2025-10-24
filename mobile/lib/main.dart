import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'core/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ProviderScope(child: LeadRoleApp()));
}

class LeadRoleApp extends StatelessWidget {
  const LeadRoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LeadRole',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),

      routerConfig: appRouter,
    );
  }
}
