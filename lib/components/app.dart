import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final userProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

final userDataProvider = StreamProvider<Map?>((ref) {
  final userStream = ref.watch(userProvider);

  var user = userStream.value;

  if (user != null) {
    var docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    return docRef.snapshots().map((doc) => doc.data());
  } else {
    return Stream.empty();
  }
});

class App extends ConsumerStatefulWidget {
  final Widget child;

  const App({super.key, required this.child});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);

    if (userData.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (userData.hasError) {
      return Center(child: Text("An error occurred loading your data."));
    }

    final List<String> roles = List<String>.from(
      userData.value?["roles"] ?? [],
    );

    final List<Map<String, dynamic>> destinations = [
      {"icon": Icon(Icons.home), "label": "Übersicht", "url": "/"},
    ];

    if (roles.contains("admin")) {
      destinations.add({
        "icon": Icon(Icons.people_alt),
        "label": "Mitglieder",
        "url": "/members",
      });
    }

    destinations.add({
      "icon": Icon(Icons.settings),
      "label": "Einstellungen",
      "url": "/settings",
    });

    final isTablet = MediaQuery.of(context).size.aspectRatio > 1;

    return SafeArea(
      child: Scaffold(
        body:
            isTablet
                ? Row(
                  spacing: 5,
                  children: [
                    NavigationRail(
                      destinations:
                          destinations.map((element) {
                            return NavigationRailDestination(
                              icon: element["icon"],
                              label: Text(element["label"]),
                            );
                          }).toList(),
                      selectedIndex: selectedIndex,
                      elevation: 5,
                      extended: true,
                      trailing: FilledButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                        },
                        child: Text("Sign Out"),
                      ),
                      onDestinationSelected: (i) {
                        setState(() {
                          selectedIndex = i;
                          context.pushReplacement(destinations[i]["url"]);
                        });
                      },
                      leading: Image.asset("assets/tvo.png", height: 75),
                    ),
                    Expanded(child: widget.child),
                  ],
                )
                : Column(
                  children: [
                    Expanded(child: widget.child),
                    NavigationBar(
                      destinations:
                          destinations.map((element) {
                            return NavigationDestination(
                              icon: element["icon"],
                              label: element["label"],
                            );
                          }).toList(),
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (i) {
                        setState(() {
                          selectedIndex = i;
                          context.pushReplacement(destinations[i]["url"]);
                        });
                      },
                      elevation: 5,
                    ),
                  ],
                ),
      ),
    );
  }
}
