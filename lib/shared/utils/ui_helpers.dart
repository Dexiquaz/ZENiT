import 'package:flutter/material.dart';

/// Shows a SnackBar with common styling
void showSnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = Colors.blue,
  Duration duration = const Duration(seconds: 2),
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
    ),
  );
}

/// Shows an error SnackBar (red background)
void showErrorSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  showSnackBar(
    context,
    message,
    backgroundColor: Colors.red,
    duration: duration,
  );
}

/// Shows a success SnackBar (green background)
void showSuccessSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  showSnackBar(
    context,
    message,
    backgroundColor: Colors.green,
    duration: duration,
  );
}

/// Shows a warning SnackBar (orange background)
void showWarningSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  showSnackBar(
    context,
    message,
    backgroundColor: Colors.orange,
    duration: duration,
  );
}

/// Shows a loading dialog with a circular progress indicator
void showLoadingDialog(BuildContext context) {
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );
}

/// Dismisses the current dialog safely
Future<void> dismissDialog(BuildContext context) async {
  if (!context.mounted) return;

  // Allow Navigator to process dialog state before popping
  await Future.delayed(const Duration(milliseconds: 100));

  if (!context.mounted) return;
  try {
    Navigator.of(context, rootNavigator: true).pop();
  } catch (_) {
    // Dialog might have already been dismissed
  }
}

/// Wraps an async operation with a loading dialog
Future<T?> withLoadingDialog<T>(
  BuildContext context,
  Future<T> Function() operation,
) async {
  showLoadingDialog(context);

  try {
    final result = await operation();
    if (!context.mounted) return null;
    await dismissDialog(context);
    return result;
  } catch (e) {
    if (!context.mounted) return null;
    await dismissDialog(context);
    rethrow;
  }
}

/// Common bottom sheet shape (rounded top corners)
const bottomSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
);

/// Common divider for list tiles (indent for icon alignment)
const dividerListTile = Divider(indent: 56);

/// Common loading indicator widget
const loadingWidget = Center(child: CircularProgressIndicator());
