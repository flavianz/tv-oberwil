import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:go_router/go_router.dart';
import 'package:tv_oberwil/components/app.dart';
import 'package:tv_oberwil/screens/admin/home.dart';
import 'package:tv_oberwil/screens/admin/member_details_page.dart';
import 'package:tv_oberwil/screens/admin/members_page.dart';
import 'package:tv_oberwil/screens/admin/team_details_page.dart';
import 'package:tv_oberwil/screens/admin/team_member_details_page.dart';
import 'package:tv_oberwil/screens/admin/teams_page.dart';
import 'package:tv_oberwil/screens/coach/team_members_page.dart';
import 'package:tv_oberwil/screens/coach/simple_event_details_edit_page.dart';
import 'package:tv_oberwil/screens/player/event_details_page.dart';
import 'package:tv_oberwil/screens/player/events_page.dart';

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
            return MembersPage(
              /*refresh: (state.uri.queryParameters["r"] ?? "false") == "true",*/
            );
          },
        ),
        GoRoute(
          path: '/admin/teams',
          builder: (context, state) {
            return TeamsPage(
              refresh: (state.uri.queryParameters["r"] ?? "false") == "true",
            );
          },
        ),
        GoRoute(
          path: '/admin/member/:uid',
          builder: (context, state) {
            final userId = state.pathParameters['uid']!;
            return MemberDetailsPage(
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
            return TeamDetailsPage(teamId: teamId);
          },
        ),
        GoRoute(
          path: '/admin/team/:uid/create',
          builder: (context, state) {
            final teamId = state.pathParameters['uid']!;
            return TeamDetailsPage(teamId: teamId, created: true);
          },
        ),
        GoRoute(
          path: '/admin/team/:teamId/team_member/:teamMemberId',
          builder: (context, state) {
            final teamId = state.pathParameters['teamId']!;
            final teamMemberId = state.pathParameters['teamMemberId']!;
            return TeamMemberDetailsPage(
              teamId: teamId,
              teamMemberId: teamMemberId,
            );
          },
        ),
        GoRoute(
          path: '/coach/team/:teamId/team_member/:teamMemberId',
          builder: (context, state) {
            final teamId = state.pathParameters['teamId']!;
            final teamMemberId = state.pathParameters['teamMemberId']!;
            return TeamMemberDetailsPage(
              teamId: teamId,
              teamMemberId: teamMemberId,
            );
          },
        ),
        GoRoute(
          path: '/admin/team/:teamId/team_members/:teamMemberId/create',
          builder: (context, state) {
            final teamId = state.pathParameters['teamId']!;
            final teamMemberId = state.pathParameters['teamMemberId']!;
            return TeamMemberDetailsPage(
              teamId: teamId,
              teamMemberId: teamMemberId,
              created: true,
            );
          },
        ),
        GoRoute(
          path: '/player/team/:team/events',
          builder: (context, state) {
            return PlayerEventsPage(teamId: state.pathParameters["team"] ?? "");
          },
        ),
        GoRoute(
          path: '/player/team/:team/event/:event',
          builder: (context, state) {
            final eventId = state.pathParameters['event']!;
            final teamId = state.pathParameters['team']!;
            return PlayerEventDetailsPage(eventId: eventId, teamId: teamId);
          },
        ),
        GoRoute(
          path: '/coach/team/:team/events',
          builder: (context, state) {
            return PlayerEventsPage(
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
            return PlayerEventDetailsPage(
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
            return SimpleEventDetailsEditPage(eventId: eventId, teamId: teamId);
          },
        ),
        GoRoute(
          path: '/coach/team/:team/event/:event/createSimple',
          builder: (context, state) {
            final eventId = state.pathParameters['event']!;
            final teamId = state.pathParameters['team']!;
            return SimpleEventDetailsEditPage(
              eventId: eventId,
              teamId: teamId,
              created: true,
            );
          },
        ),
        GoRoute(
          path: '/coach/team/:team',
          builder: (context, state) {
            final teamId = state.pathParameters['team']!;
            return CoachTeamMembersPage(teamId: teamId);
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
