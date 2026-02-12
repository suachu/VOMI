import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vomi/core/theme/colors.dart';
import 'package:vomi/services/user_profile_local_service.dart';
import 'package:vomi/views/auth/pages/landing_page.dart';
import 'package:vomi/views/auth/widgets/screen_frame.dart';
import 'package:vomi/views/main/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: AppColors.background),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  final UserProfileLocalService _profileService = const UserProfileLocalService();
  String? _initializedUid;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const _SplashScreen();
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (authSnapshot.data == null) {
          return const LandingPage();
        }
        final user = authSnapshot.data!;
        if (_initializedUid != user.uid) {
          _initializedUid = user.uid;
          _profileService.ensure(user);
        }
        return const MainShell();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenFrame(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 94.95,
              top: 325,
              child: Image.asset(
                'assets/images/V.png',
                width: 160,
                height: 179,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 170.95,
              top: 470,
              child: Image.asset(
                'assets/images/omi.png',
                width: 146,
                height: 31,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
