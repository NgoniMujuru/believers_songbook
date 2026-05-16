import 'package:believers_songbook/account_page.dart';
import 'package:believers_songbook/l10n/app_localizations.dart';
import 'package:believers_songbook/providers/auth_provider.dart';
import 'package:believers_songbook/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A small cloud icon for the AppBar that reflects sync / auth status.
///
/// - Signed in  → green cloud-done icon
/// - Not signed in → grey cloud-off icon
///
/// Tapping it navigates to the Account page.
class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final bool signedIn = auth.isSignedIn;

        return IconButton(
          tooltip: signedIn ? AppLocalizations.of(context)!.accountSyncingEnabled : AppLocalizations.of(context)!.accountSignInTitle,
          icon: Icon(
            signedIn ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 22,
            color: signedIn
                ? Styles.themeColor
                : Theme.of(context).iconTheme.color?.withValues(alpha: 0.45),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountPage()),
            );
          },
        );
      },
    );
  }
}
