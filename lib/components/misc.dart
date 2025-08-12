import 'package:flutter/material.dart';

Widget getPill(String s, Color c, bool lightText) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    margin: EdgeInsets.only(left: 10),
    decoration: BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      s,
      style: TextStyle(fontSize: 12, color: lightText ? Colors.white : null),
    ),
  );
}

Widget getPositionPill(position) {
  switch (position) {
    case "forward":
      return getPill("Stürmer", Colors.lightBlueAccent, true);
    case "center":
      return getPill("Center", Colors.greenAccent, false);
    case "defense":
      return getPill("Verteidigung", Colors.amberAccent, false);
    case "keeper":
      return getPill("Torhüter", Colors.redAccent, true);
    default:
      return getPill("Keine", Colors.grey, true);
  }
}

Widget getRolePill(role) {
  switch (role) {
    case "player":
      return getPill("Spieler", Colors.grey, true);
    case "no_licence":
      return getPill("Keine Lizenz", Colors.amberAccent, true);
    case "coach":
      return getPill("Trainer", Colors.green, true);
    case "assistant_coach":
      return getPill("Assistentstrainer", Colors.greenAccent, false);
    default:
      return getPill("Keine", Colors.grey, true);
  }
}

Widget getBoolPill(value) {
  switch (value) {
    case true:
    case "true":
      return getPill("Ja", Colors.green, true);
    case false:
    case "false":
      return getPill("Nein", Colors.red, true);
    default:
      return getPill("Keine Angabe", Colors.grey, true);
  }
}

Widget getGenderPill(gender) {
  switch (gender) {
    case "men":
      return getPill("Herren", Colors.lightBlue, true);
    case "women":
      return getPill("Damen", Colors.pink, true);
    case "mixed":
      return getPill("Gemischt", Colors.amber, false);
    default:
      return getPill("Keine Angabe", Colors.grey, true);
  }
}
