import 'package:flutter/material.dart';

class CustomSnackbar {
  static successful({
    required String message,
    required BuildContext context,
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.green,
    Color textColor = Colors.black,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ));
  }

  static void error({
    required String message,
    required BuildContext context,
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.red,
    Color textColor = Colors.white,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ));
  }
}
