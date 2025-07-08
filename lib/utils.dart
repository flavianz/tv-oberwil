import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String generateFirestoreKey() {
  const String chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const int length = 20;
  final Random random = Random.secure();

  return List.generate(
    length,
    (index) => chars[random.nextInt(chars.length)],
  ).join();
}

final textControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

String getWeekday(int weekday) {
  switch (weekday) {
    case 1:
      return "Montag";
    case 2:
      return "Dienstag";
    case 3:
      return "Mittwoch";
    case 4:
      return "Donnerstag";
    case 5:
      return "Freitag";
    case 6:
      return "Samstag";
    case 7:
      return "Sonntag";
    case _:
      return "Unbekannt";
  }
}

DateTime getDateTime(dynamic timestamp) {
  return DateTime.fromMillisecondsSinceEpoch(
    ((timestamp ?? Timestamp.now()) as Timestamp).millisecondsSinceEpoch,
  );
}

String getTimeDistance(DateTime date) {
  DateTime now = DateTime.now();
  int difference = date.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
  if (difference < 1000 * 3600 * 24) {
    return "Heute";
  } else if (difference < 1000 * 3600 * 24 * 2) {
    return "Morgen";
  } else if (difference < 1000 * 3600 * 24 * 7 && date.weekday > now.weekday) {
    return "Diese Woche";
  } else if (difference < 1000 * 3600 * 24 * 7 ||
      (difference < 1000 * 3600 * 24 * 14 && date.weekday > now.weekday)) {
    return "Nächste Woche";
  } else if (difference < 1000 * 3600 * 24 * 30 && date.month == now.month) {
    return "Dieser Monat";
  } else if (difference < 1000 * 3600 * 24 * 30 &&
      date.month == now.month + 1) {
    return "Nächster Monat";
  } else {
    return "In ${difference / (1000 * 3600 * 24 * 30)} Monaten";
  }
}

bool isSameDay(DateTime first, DateTime second) {
  return first.day == second.day &&
      first.month == second.month &&
      first.year == second.year;
}

String? getNearbyTimeDifference(DateTime date) {
  final now = DateTime.now();
  if (isSameDay(now, date)) {
    return "Heute";
  }
  if (isSameDay(
    DateTime.fromMillisecondsSinceEpoch(
      now.millisecondsSinceEpoch + 1000 * 3600 * 24,
    ),
    date,
  )) {
    return "Morgen";
  }
  return null;
}
