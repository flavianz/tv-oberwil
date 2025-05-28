import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WebShell extends StatelessWidget {
  final Widget child;

  const WebShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.fromRGBO(248, 250, 252, 1.0),
      child: Row(
        children: [
          const Column(
            children: [
              NavButton(
                icon: CupertinoIcons.person_2,
                label: "Mitglieder",
                link: "/members",
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String link;

  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Row(children: [Icon(icon), Text(label)]),
      ),
      onTap: () {
        context.go(link);
      },
    );
  }
}
