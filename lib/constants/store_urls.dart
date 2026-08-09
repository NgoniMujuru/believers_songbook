import 'dart:io' show Platform;

class AppStoreLinks {
  static const String iosAppId = '1667531237';
  static const String androidPackageId = 'com.ngonimujuru.songbook_for_believers';

  static const String iosUrl =
      'https://apps.apple.com/app/songbook-for-believers/id$iosAppId';
  static const String androidUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';
  // TODO: replace with the real Microsoft Store URL once the Partner Center
  // listing is published.
  static const String windowsUrl =
      'https://apps.microsoft.com/detail/TODO-fill-in-after-partner-center-reservation';

  static String get currentPlatformUrl {
    if (Platform.isIOS) return iosUrl;
    if (Platform.isWindows) return windowsUrl;
    return androidUrl;
  }
}
