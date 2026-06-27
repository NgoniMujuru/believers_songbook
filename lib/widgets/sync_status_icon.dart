import 'dart:async';

import 'package:believers_songbook/account_page.dart';
import 'package:believers_songbook/providers/auth_provider.dart';
import 'package:believers_songbook/services/sync_runner.dart';
import 'package:believers_songbook/styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SyncStatusIcon extends StatefulWidget {
  const SyncStatusIcon({super.key});

  @override
  State<SyncStatusIcon> createState() => _SyncStatusIconState();
}

class _SyncStatusIconState extends State<SyncStatusIcon> {
  final MenuController _menu = MenuController();
  final LayerLink _link = LayerLink();
  // One shared clock drives both the inline label and the (open) menu header,
  // so their relative times always match and refresh together.
  final ValueNotifier<int> _tick = ValueNotifier(0);
  Timer? _ticker;
  OverlayEntry? _tip; // persistent long-press tooltip
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _tick.value++);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tick.dispose();
    _removeTip();
    super.dispose();
  }

  // ─── Long-press tooltip: stays until you tap anywhere ─────────────
  void _removeTip() {
    _tip?.remove();
    _tip = null;
  }

  void _showTip() {
    _removeTip();
    final auth = context.read<AuthProvider>();
    final last = auth.lastSyncedAt;
    final String text = !auth.isSignedIn
        ? 'Sign in to sync'
        : last != null
            ? 'Last synced ${_exact(last)}'
            : 'Signed in — not synced yet';
    _tip = OverlayEntry(
      builder: (ctx) {
        // Inverse surface so the bubble contrasts with the current theme:
        // dark-on-light in light mode, light-on-dark in dark mode.
        final scheme = Theme.of(ctx).colorScheme;
        return Stack(
          children: [
            // Any tap (or tapping the cloud again) dismisses it.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _removeTip,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 6),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.inverseSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    text,
                    style:
                        TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_tip!);
  }

  Future<void> _syncNow() async {
    _menu.close();
    setState(() => _syncing = true);
    final ok = await SyncRunner.run(context);
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Synced' : 'Sync failed'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openAccount() {
    _menu.close();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountPage()),
    );
  }

  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative || diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 28) return '${diff.inDays ~/ 7}w ago';
    return DateFormat('d MMM').format(dt.toLocal()); // e.g. "5 Mar"
  }

  String _exact(DateTime dt) =>
      DateFormat('MMM d, y • h:mm a').format(dt.toLocal());

  List<Widget> _menuItems(BuildContext context, bool signedIn, DateTime? last) {
    final theme = Theme.of(context);

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  signedIn
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  size: 18,
                  color: signedIn
                      ? Styles.themeColor
                      : theme.iconTheme.color?.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<int>(
                  valueListenable: _tick,
                  builder: (context, _, __) {
                    final status = !signedIn
                        ? 'Sign in to sync'
                        : _syncing
                            ? 'Syncing…'
                            : last != null
                                ? 'Synced ${_relative(last)}'
                                : 'Not synced yet';
                    return Text(status,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600));
                  },
                ),
              ],
            ),
            if (signedIn && last != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 26),
                child: Text(_exact(last),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ),
          ],
        ),
      ),
      const Divider(height: 10),
      if (signedIn)
        MenuItemButton(
          leadingIcon: const Icon(Icons.sync, size: 20),
          onPressed: _syncNow,
          child: const Text('Sync now'),
        ),
      MenuItemButton(
        leadingIcon:
            Icon(signedIn ? Icons.person_outline : Icons.login, size: 20),
        onPressed: _openAccount,
        child: Text(signedIn ? 'Account' : 'Sign in'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final bool signedIn = auth.isSignedIn;
        final DateTime? last = auth.lastSyncedAt;
        final Color muted =
            Theme.of(context).iconTheme.color?.withValues(alpha: 0.45) ??
                Colors.grey;
        final bool showLabel = signedIn && last != null;

        return CompositedTransformTarget(
          link: _link,
          child: MenuAnchor(
            controller: _menu,
            alignmentOffset: const Offset(0, 4),
            style: MenuStyle(
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            menuChildren: _menuItems(context, signedIn, last),
            builder: (context, controller, child) {
              return InkWell(
                customBorder: const StadiumBorder(),
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                onLongPress: _showTip,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        signedIn
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        size: 22,
                        color: signedIn ? Styles.themeColor : muted,
                      ),
                      if (showLabel) ...[
                        const SizedBox(width: 3),
                        ValueListenableBuilder<int>(
                          valueListenable: _tick,
                          builder: (context, _, __) => Text(
                            _syncing ? 'syncing…' : _relative(last),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Styles.themeColor.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
