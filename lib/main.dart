import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tv_oberwil/firebase_options.dart';
import 'package:tv_oberwil/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseUIAuth.configureProviders([
    GoogleProvider(
      clientId:
          "1062038376839-recum2ohkiio87nqmdp81lpm8njvmr1m.apps.googleusercontent.com",
    ),
    EmailAuthProvider(),
  ]);

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final activeRouter = router;
  late final StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        activeRouter.go("/sign-in");
      }
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.green,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: activeRouter,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        textTheme: ThemeData.light().textTheme.copyWith(
          bodyMedium: const TextStyle(fontSize: 17),
        ),
      ),
    );
  }
}
