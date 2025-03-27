
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invist_bh/firebase_options.dart';
import 'package:invist_bh/screens/main_navigation_page.dart';
import 'package:invist_bh/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: InvistBhApp()));
}

class InvistBhApp extends StatelessWidget {
  const InvistBhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INVIST.BH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainNavigationPage(),
    );
  }
}

