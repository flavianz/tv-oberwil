import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/app.dart';
import 'package:tv_oberwil/screens/home_screen.dart';
import 'package:tv_oberwil/screens/member_details_screen.dart';
import 'package:tv_oberwil/screens/members_screen.dart';
import 'package:tv_oberwil/screens/team_details_screen.dart';
import 'package:tv_oberwil/screens/teams_screen.dart';

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return App(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => HomeScreen()),
        GoRoute(
          path: '/members',
          builder: (context, state) {
            return MembersScreen(
              refresh: (state.uri.queryParameters["r"] ?? "false") == "true",
            );
          },
        ),
        GoRoute(
          path: '/teams',
          builder: (context, state) {
            return TeamsScreen(
              refresh: (state.uri.queryParameters["r"] ?? "false") == "true",
            );
          },
        ),
        GoRoute(
          path: '/member/:uid',
          builder: (context, state) {
            final userId = state.pathParameters['uid']!;
            return MemberDetailsScreen(
              uid: userId,
              created:
                  (state.uri.queryParameters["create"] ?? "false") == "true",
            );
          },
        ),
        GoRoute(
          path: '/team/:uid',
          builder: (context, state) {
            final teamId = state.pathParameters['uid']!;
            return TeamDetailsScreen(
              uid: teamId,
              created:
                  (state.uri.queryParameters["create"] ?? "false") == "true",
            );
          },
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
              if (FirebaseAuth.instance.currentUser != null &&
                  !FirebaseAuth.instance.currentUser!.emailVerified) {
                FirebaseAuth.instance.currentUser!.sendEmailVerification();
              }
              context.go('/');
            }),
            AuthStateChangeAction<SignedIn>((context, state) {
              context.go('/');
            }),
          ],
        );
      },
    ),
  ],
);
