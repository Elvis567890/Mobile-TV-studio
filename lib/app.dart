import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'role_chooser.dart';
import 'data/app_settings.dart';
import 'ui/theme.dart';

class MobileTvStudioApp extends StatelessWidget {
  const MobileTvStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppSettings()..load(),
      child: MaterialApp(
        title: 'Mobile TV Studio',
        debugShowCheckedModeBanner: false,
        theme: buildStudioTheme(),
        home: const RoleChooser(),
      ),
    );
  }
}
