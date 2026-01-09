// lib/utils/helpers.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<bool> showConfirmDialog(BuildContext context, {required String title, required String message, String confirmText = 'Confirm'}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmText)),
        ],
      ),
    );
    return result ?? false;
  }

  static String formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);
  
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  static void log(String message, {String tag = 'APP'}) {
    print('[$tag] $message');
  }

  static String parseApiError(dynamic e) => e.toString().replaceAll('Exception: ', '');
}