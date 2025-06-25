import 'package:flutter/material.dart';

/// A common dialog function that can be reused throughout the app.
Future<void> showCommonDialog({
  required BuildContext context,
  required String title,
  required String message,
  required List<DialogAction> actions,
  bool barrierDismissible = false,
}) async {
  if (!context.mounted) return;

  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: actions.map((action) {
        return TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            action.onPressed?.call();
          },
          child: Text(action.label),
        );
      }).toList(),
    ),
  );
}

/// A class to define action buttons for the dialog
class DialogAction {
  final String label;
  final VoidCallback? onPressed;

  DialogAction({
    required this.label,
    this.onPressed,
  });
}

/// A reusable loading dialog
Future<void> showLoadingDialog(BuildContext context,
    {bool barrierDismissible = false}) async {
  if (!context.mounted) return;

  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
}

/// Dismiss the current dialog
void dismissDialog(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.of(context).pop();
  }
}

/// Show a snackbar message
void showSnackBarMessage(BuildContext context, String message) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
