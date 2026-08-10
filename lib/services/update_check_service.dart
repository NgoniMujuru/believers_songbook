import 'package:believers_songbook/constants/store_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateCheckResult {
  final bool shouldShowPopup;
  final String storeVersion;
  final String storeUrl;

  const UpdateCheckResult({
    required this.shouldShowPopup,
    required this.storeVersion,
    required this.storeUrl,
  });

  static const none = UpdateCheckResult(
    shouldShowPopup: false,
    storeVersion: '',
    storeUrl: '',
  );
}

class UpdateCheckService {
  UpdateCheckService._();

  static final UpdateCheckService instance = UpdateCheckService._();

  static const _lastCheckedAtKey = 'updateCheck_lastCheckedAt';
  static const _pendingVersionKey = 'updateCheck_pendingVersion';
  static const _firstDetectedAtKey = 'updateCheck_newVersionFirstDetectedAt';
  static const _dismissedVersionKey = 'updateCheck_dismissedVersion';

  static const _checkThrottle = Duration(hours: 24);
  static const _gracePeriod = Duration(days: 14);

  /// Debug-only override: when set, this version string is used instead of
  /// hitting the store, so the "update available" path can be exercised
  /// without waiting for a real store release.
  static String? debugForcedStoreVersion;

  /// Debug-only override: when true, newly-detected versions are recorded
  /// as first-detected 15 days ago, so the popup shows on the very next
  /// launch instead of waiting out the real 14-day grace period.
  static bool debugForceOverdue = false;

  Future<UpdateCheckResult> checkForUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    String? storeVersion;
    final lastCheckedAtMs = prefs.getInt(_lastCheckedAtKey);
    final throttled = lastCheckedAtMs != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastCheckedAtMs)) <
            _checkThrottle;

    if (kDebugMode && debugForcedStoreVersion != null) {
      storeVersion = debugForcedStoreVersion;
    } else if (!throttled) {
      storeVersion = await _fetchStoreVersion();
      if (storeVersion != null) {
        await prefs.setInt(_lastCheckedAtKey, now.millisecondsSinceEpoch);
      }
    }

    // If we didn't get a fresh result (throttled or fetch failed), fall back
    // to whatever version we already had cached as pending.
    storeVersion ??= prefs.getString(_pendingVersionKey);
    if (storeVersion == null) return UpdateCheckResult.none;

    final installedVersion = await _fetchInstalledVersion();
    if (compareVersions(storeVersion, installedVersion) <= 0) {
      // Already up to date (or ahead) — clear any tracked state.
      await prefs.remove(_pendingVersionKey);
      await prefs.remove(_firstDetectedAtKey);
      await prefs.remove(_dismissedVersionKey);
      return UpdateCheckResult.none;
    }

    final pendingVersion = prefs.getString(_pendingVersionKey);
    if (storeVersion != pendingVersion) {
      // Newly detected update, or one that supersedes a previously
      // dismissed version — reset the cycle and start a fresh grace period.
      final firstDetectedAt = (kDebugMode && debugForceOverdue)
          ? now.subtract(_gracePeriod).subtract(const Duration(days: 1))
          : now;
      await prefs.setString(_pendingVersionKey, storeVersion);
      await prefs.setInt(
          _firstDetectedAtKey, firstDetectedAt.millisecondsSinceEpoch);
      await prefs.remove(_dismissedVersionKey);
      return UpdateCheckResult.none;
    }

    final firstDetectedAtMs = prefs.getInt(_firstDetectedAtKey);
    if (firstDetectedAtMs == null) return UpdateCheckResult.none;
    final firstDetectedAt = DateTime.fromMillisecondsSinceEpoch(firstDetectedAtMs);
    final isOverdue = now.difference(firstDetectedAt) >= _gracePeriod;
    final dismissedVersion = prefs.getString(_dismissedVersionKey);

    if (isOverdue && dismissedVersion != storeVersion) {
      return UpdateCheckResult(
        shouldShowPopup: true,
        storeVersion: storeVersion,
        storeUrl: AppStoreLinks.currentPlatformUrl,
      );
    }
    return UpdateCheckResult.none;
  }

  Future<void> markDismissed(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
  }

  // new_version_plus has no Microsoft Store parameter, so this silently
  // returns null on Windows (caught below) and the update prompt never
  // fires there. Accepted gap — no MS Store version-check API to use instead.
  Future<String?> _fetchStoreVersion() async {
    try {
      final newVersion = NewVersionPlus(
        iOSId: AppStoreLinks.iosAppId,
        androidId: AppStoreLinks.androidPackageId,
      );
      final status = await newVersion.getVersionStatus();
      return status?.storeVersion;
    } catch (_) {
      return null;
    }
  }

  Future<String> _fetchInstalledVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  @visibleForTesting
  int compareVersions(String a, String b) {
    final aParts = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final bParts = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final length = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < length; i++) {
      final aPart = i < aParts.length ? aParts[i] : 0;
      final bPart = i < bParts.length ? bParts[i] : 0;
      if (aPart != bPart) return aPart.compareTo(bPart);
    }
    return 0;
  }
}
