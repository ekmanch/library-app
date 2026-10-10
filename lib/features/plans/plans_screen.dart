import 'package:flutter/material.dart';

import '../../widgets/page_header.dart';
import '../shell/app_shell.dart';

/// Placeholder until S5 is built in phase 1e.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppShell.contentBottomPadding),
          children: [
            PageHeader(
              title: 'Plans',
              actions: [SettingsButton(onPressed: () {})],
            ),
          ],
        ),
      ),
    );
  }
}
