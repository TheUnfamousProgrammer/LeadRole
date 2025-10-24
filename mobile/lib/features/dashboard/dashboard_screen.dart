import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:leadrole/features/jobs/discover_tab.dart';
import 'package:leadrole/features/jobs/my_productions_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          title: const Text(
            'LeadRole',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Card(
              color: AppColors.neon,
              elevation: 2,
              shadowColor: AppColors.neonSoft,
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Image.asset("assets/images/icon.png"),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: AppColors.bgDark,
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.bgDark),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.clear().then((_) {
                                context.pushReplacement("/auth");
                              });
                            });
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(
            indicatorColor: AppColors.neon,
            tabs: [
              Tab(text: 'My Productions'),
              Tab(text: 'Discover'),
            ],
          ),
        ),
        body: const TabBarView(children: [MyProductionTab(), DiscoverTab()]),
      ),
    );
  }
}
