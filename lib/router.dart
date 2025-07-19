import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/app.dart';
import 'package:tv_oberwil/screens/admin/home_screen.dart';
import 'package:tv_oberwil/screens/admin/member_details_screen.dart';
import 'package:tv_oberwil/screens/admin/members_screen.dart';
import 'package:tv_oberwil/screens/admin/team_details_screen.dart';
import 'package:tv_oberwil/screens/admin/teams_screen.dart';
import 'package:tv_oberwil/screens/coach/simple_event_details_edit.dart';
import 'package:tv_oberwil/screens/player/event_details.dart';
import 'package:tv_oberwil/screens/player/events.dart';

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return App(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => HomeScreen()),
        GoRoute(
          routes: [],
          path: '/admin/members',
          builder: (context, state) {
            return MembersScreen(
              refresh: (state.uri.queryParameters["r"] ?? "false") == "true",
            );
          },
        ),
        GoRoute(
          path: '/admin/teams',
          builder: (context, state) {
            return TeamsScreen(
              refresh: (state.uri.queryParameters["r"] ?? "false") == "true",
            );
          },
        ),
        GoRoute(
          path: '/admin/member/:uid',
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
          path: '/admin/team/:uid',
          builder: (context, state) {
            final teamId = state.pathParameters['uid']!;
            return TeamDetailsScreen(
              uid: teamId,
              created:
                  (state.uri.queryParameters["create"] ?? "false") == "true",
            );
          },
        ),
        GoRoute(
          path: '/player/team/:team/events',
          builder: (context, state) {
            return PlayerEvents(teamId: state.pathParameters["team"] ?? "");
          },
        ),
        GoRoute(
          path: '/player/team/:team/event/:event',
          builder: (context, state) {
            final eventId = state.pathParameters['event']!;
            final teamId = state.pathParameters['team']!;
            return PlayerEventDetails(eventId: eventId, teamId: teamId);
          },
        ),
        GoRoute(
          path: '/coach/team/:team/events',
          builder: (context, state) {
            return PlayerEvents(
              teamId: state.pathParameters["team"] ?? "",
              isCoach: true,
            );
          },
        ),
        GoRoute(
          path: '/coach/team/:team/event/:event',
          builder: (context, state) {
            final eventId = state.pathParameters['event']!;
            final teamId = state.pathParameters['team']!;
            return PlayerEventDetails(
              eventId: eventId,
              teamId: teamId,
              isCoach: true,
            );
          },
        ),
        GoRoute(
          path: '/coach/team/:team/event/:event/edit',
          builder: (context, state) {
            final eventId = state.pathParameters['event']!;
            final teamId = state.pathParameters['team']!;
            return SimpleEventDetailsEdit(eventId: eventId, teamId: teamId);
          },
        ),
        GoRoute(
          path: '/coach/team/:team/event/:event/createSimple',
          builder: (context, state) {
            final eventId = state.pathParameters['event']!;
            final teamId = state.pathParameters['team']!;
            return SimpleEventDetailsEdit(
              eventId: eventId,
              teamId: teamId,
              created: true,
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
