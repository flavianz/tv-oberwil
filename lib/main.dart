import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/firebase_options.dart';
import 'package:tv_oberwil/screens/home.dart';
import 'package:tv_oberwil/screens/presence.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
  });
  FirebaseUIAuth.configureProviders([
    GoogleProvider(
      clientId:
          "1062038376839-recum2ohkiio87nqmdp81lpm8njvmr1m.apps.googleusercontent.com",
    ),
    EmailAuthProvider(),
  ]);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation:
          FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return Scaffold(
              appBar: AppBar(title: const Text('My App')),
              bottomNavigationBar: MyBottomNavBar(),
              body: child,
            );
          },
          routes: [
            GoRoute(path: '/', builder: (context, state) => HomeScreen()),
            GoRoute(
              path: '/settings',
              builder: (context, state) => PresenceScreen(),
            ),
          ],
        ),
        GoRoute(
          path: "/sign-in",
          builder: (context, state) {
            return SignInScreen(
              providers: [
                EmailAuthProvider(),
                GoogleProvider(
                  clientId:
                      "1062038376839-recum2ohkiio87nqmdp81lpm8njvmr1m.apps.googleusercontent.com",
                ),
              ],
              actions: [
                AuthStateChangeAction<UserCreated>((context, state) {
                  // Put any new user logic here
                  context.push('/verify-email');
                }),
                AuthStateChangeAction<SignedIn>((context, state) {
                  if (!state.user!.emailVerified) {
                    context.push('/verify-email');
                  } else {
                    context.pushReplacement('/');
                  }
                }),
              ],
            );
          },
        ),
        GoRoute(
          path: "/verify-email",
          builder:
              (context, state) => EmailVerificationScreen(
                actions: [
                  EmailVerifiedAction(() {
                    context.pushReplacement('/');
                  }),
                  AuthCancelledAction((context) {
                    FirebaseUIAuth.signOut(context: context);
                    context.pushReplacement('/');
                  }),
                ],
              ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }
}

class MyBottomNavBar extends StatelessWidget {
  const MyBottomNavBar({super.key});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/settings') return 1;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
