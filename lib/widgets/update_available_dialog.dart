import 'package:believers_songbook/l10n/app_localizations.dart';
import 'package:believers_songbook/styles.dart';
import 'package:flutter/material.dart';

Future<void> showUpdateAvailableDialog(
  BuildContext context, {
  required VoidCallback onUpdate,
  required VoidCallback onDismiss,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.system_update, size: 48, color: Styles.themeColor),
      title: Text(l10n.updateAvailableTitle),
      content: Text(
        l10n.updateAvailableBody,
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onDismiss();
          },
          child: Text(l10n.updateAvailableActionLater),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onUpdate();
          },
          style: FilledButton.styleFrom(
            backgroundColor: Styles.themeColor,
          ),
          child: Text(l10n.updateAvailableActionUpdate),
        ),
      ],
    ),
  );
}
