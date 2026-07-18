import 'dart:io' show Platform;

class AppStoreLinks {
  static const String iosAppId = '1667531237';
  static const String androidPackageId = 'com.ngonimujuru.songbook_for_believers';

  static const String iosUrl =
      'https://apps.apple.com/app/songbook-for-believers/id$iosAppId';
  static const String androidUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  static String get currentPlatformUrl => Platform.isIOS ? iosUrl : androidUrl;
}
