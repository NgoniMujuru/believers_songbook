import 'package:believers_songbook/l10n/app_localizations.dart';
import 'package:believers_songbook/providers/auth_provider.dart';
import 'package:believers_songbook/widgets/google_logo.dart';
import 'package:believers_songbook/providers/collections_data.dart';
import 'package:believers_songbook/providers/main_page_settings.dart';
import 'package:believers_songbook/providers/song_book_settings.dart';
import 'package:believers_songbook/providers/song_settings.dart';
import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:believers_songbook/services/analytics_service.dart';
import 'package:believers_songbook/services/sync_service.dart';
import 'package:believers_songbook/styles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isSignedIn) {
          return _SignedInView();
        } else {
          return _SignInView();
        }
      },
    );
  }
}

class _SignInView extends StatefulWidget {
  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  bool _isCreateAccount = false;
  bool _showEmailForm = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) => Consumer<MainPageSettings>(
        builder: (context, mainPageSettings, child) => Localizations.override(
          context: context,
          locale: Locale(mainPageSettings.getLocale),
          child: Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.accountPageTitle),
              scrolledUnderElevation: 4,
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: MediaQuery.of(context).size.width > 600
                      ? const EdgeInsets.fromLTRB(80, 20, 80, 40)
                      : const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_sync,
                        size: 80,
                        color: Styles.themeColor,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isCreateAccount
                            ? AppLocalizations.of(context)!.accountCreateAccountTitle
                            : AppLocalizations.of(context)!.accountSignInTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.accountSyncDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (auth.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email/password form
                      if (_showEmailForm) ...[
                        _buildEmailForm(context, auth),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showEmailForm = false;
                              _isCreateAccount = false;
                            });
                            auth.clearError();
                          },
                          child: Text(AppLocalizations.of(context)!.accountBackToSignInOptions),
                        ),
                      ] else ...[
                        // Google Sign-In button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: auth.isLoading
                                ? null
                                : () => _handleGoogleSignIn(context),
                            icon: const GoogleLogo(size: 22),
                            label: Text(AppLocalizations.of(context)!.accountContinueWithGoogle),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Apple Sign-In button (iOS/macOS only)
                        if (!kIsWeb &&
                            (defaultTargetPlatform == TargetPlatform.iOS ||
                                defaultTargetPlatform == TargetPlatform.macOS)) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: auth.isLoading
                                  ? null
                                  : () => _handleAppleSignIn(context),
                              icon: const Icon(Icons.apple, size: 28),
                              label: Text(AppLocalizations.of(context)!.accountContinueWithApple),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Email sign-in button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: auth.isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _showEmailForm = true;
                                      _isCreateAccount = false;
                                    });
                                    auth.clearError();
                                  },
                            icon: const Icon(Icons.email_outlined, size: 24),
                            label: Text(AppLocalizations.of(context)!.accountContinueWithEmail),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (auth.isLoading) ...[
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                      const SizedBox(height: 32),
                      TextButton(
                        onPressed: () {
                          AnalyticsService.instance.trackSignInSkipped();
                          Navigator.of(context).pop();
                        },
                        child: Text(AppLocalizations.of(context)!.accountSkipForNow),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(BuildContext context, AuthProvider auth) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isCreateAccount)
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.accountNameLabel,
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
          if (_isCreateAccount) const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: l10n.accountEmailLabel,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.accountEmailValidatorEmpty;
              }
              if (!value.contains('@') || !value.contains('.')) {
                return l10n.accountEmailValidatorInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: l10n.accountPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.accountPasswordValidatorEmpty;
              }
              if (_isCreateAccount && value.length < 6) {
                return l10n.accountPasswordValidatorTooShort;
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleEmailSubmit(context),
          ),
          const SizedBox(height: 8),
          // Forgot password (sign-in mode only)
          if (!_isCreateAccount)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _handleForgotPassword(context),
                child: Text(l10n.accountForgotPassword),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : () => _handleEmailSubmit(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_isCreateAccount ? l10n.accountCreateAccountTitle : l10n.accountSignIn),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_isCreateAccount
                  ? l10n.accountAlreadyHaveAccount
                  : l10n.accountDontHaveAccount),
              TextButton(
                onPressed: () {
                  setState(() => _isCreateAccount = !_isCreateAccount);
                  auth.clearError();
                },
                child: Text(_isCreateAccount ? l10n.accountSignIn : l10n.accountCreateOne),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleEmailSubmit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    // Capture navigator and providers before the async sign-in call.
    // The Consumer in AccountPage will dispose this State when auth
    // state changes, so context.read / mounted will no longer work.
    final navigator = Navigator.of(context);
    final songSettings = context.read<SongSettings>();
    final themeSettings = context.read<ThemeSettings>();
    final mainPageSettings = context.read<MainPageSettings>();
    final songBookSettings = context.read<SongBookSettings>();
    final collectionsData = context.read<CollectionsData>();

    bool success;
    if (_isCreateAccount) {
      success = await auth.createAccountWithEmail(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
    } else {
      success = await auth.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    }
    if (!success) return;

    if (_isCreateAccount) {
      await AnalyticsService.instance.trackSignUp(method: 'email');
    } else {
      await AnalyticsService.instance.trackLogin(method: 'email');
    }
    await _syncAfterSignIn(
      songSettings: songSettings,
      themeSettings: themeSettings,
      mainPageSettings: mainPageSettings,
      songBookSettings: songBookSettings,
      collectionsData: collectionsData,
    );
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _handleForgotPassword(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final enterEmailFirst = l10n.accountForgotPasswordEnterEmailFirst;
    final resetEmailSentTo = l10n.accountPasswordResetEmailSentTo;
    final resetFailed = l10n.accountPasswordResetFailed;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      final auth = context.read<AuthProvider>();
      auth.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enterEmailFirst)),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendPasswordReset(email);
    if (sent) AnalyticsService.instance.trackPasswordResetRequested();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent
              ? '$resetEmailSentTo $email'
              : auth.error ?? resetFailed),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final songSettings = context.read<SongSettings>();
    final themeSettings = context.read<ThemeSettings>();
    final mainPageSettings = context.read<MainPageSettings>();
    final songBookSettings = context.read<SongBookSettings>();
    final collectionsData = context.read<CollectionsData>();

    debugPrint('[HANDLER] _handleGoogleSignIn: calling signInWithGoogle...');
    final success = await auth.signInWithGoogle();
    debugPrint('[HANDLER] signInWithGoogle returned success=$success');
    if (!success) return;

    await AnalyticsService.instance.trackLogin(method: 'google');
    debugPrint('[HANDLER] Calling _syncAfterSignIn...');
    await _syncAfterSignIn(
      songSettings: songSettings,
      themeSettings: themeSettings,
      mainPageSettings: mainPageSettings,
      songBookSettings: songBookSettings,
      collectionsData: collectionsData,
    );
    debugPrint('[HANDLER] _syncAfterSignIn done. isDarkMode=${themeSettings.isDarkMode}, locale=${mainPageSettings.getLocale}');
    debugPrint('[HANDLER] Popping AccountPage...');
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final songSettings = context.read<SongSettings>();
    final themeSettings = context.read<ThemeSettings>();
    final mainPageSettings = context.read<MainPageSettings>();
    final songBookSettings = context.read<SongBookSettings>();
    final collectionsData = context.read<CollectionsData>();

    final success = await auth.signInWithApple();
    if (!success) return;

    await AnalyticsService.instance.trackLogin(method: 'apple');
    await _syncAfterSignIn(
      songSettings: songSettings,
      themeSettings: themeSettings,
      mainPageSettings: mainPageSettings,
      songBookSettings: songBookSettings,
      collectionsData: collectionsData,
    );
    if (navigator.canPop()) navigator.pop();
  }

  /// After signing in, pull cloud data first (cloud wins), then push local data.
  /// Accepts providers directly because the calling widget may be disposed
  /// by AccountPage's Consumer rebuild before this method runs.
  static Future<void> _syncAfterSignIn({
    required SongSettings songSettings,
    required ThemeSettings themeSettings,
    required MainPageSettings mainPageSettings,
    required SongBookSettings songBookSettings,
    required CollectionsData collectionsData,
  }) async {
    debugPrint('[SYNC] _syncAfterSignIn START');
    final prefs = await SharedPreferences.getInstance();

    // Pull cloud settings first — cloud wins for returning users
    final cloudSettings = await SyncService.pullSettings();
    debugPrint('[SYNC] pullSettings returned: $cloudSettings');
    // Debug marker: write sync result to SharedPreferences for adb inspection
    prefs.setString('_debug_sync', 'cloud=$cloudSettings');

    if (cloudSettings != null && cloudSettings.isNotEmpty) {
      debugPrint('[SYNC] Applying cloud settings...');
      if (cloudSettings['fontSize'] != null) {
        songSettings.setFontSize((cloudSettings['fontSize'] as num).toDouble());
      }
      if (cloudSettings['displayKey'] != null) {
        songSettings.setDisplayKey(cloudSettings['displayKey'] as bool);
      }
      if (cloudSettings['displaySongNumber'] != null) {
        songSettings.setDisplaySongNumber(cloudSettings['displaySongNumber'] as bool);
      }
      if (cloudSettings['isDarkMode'] != null) {
        debugPrint('[SYNC] Setting isDarkMode=${cloudSettings['isDarkMode']}');
        themeSettings.setIsDarkMode(cloudSettings['isDarkMode'] as bool);
      }
      if (cloudSettings['locale'] != null) {
        debugPrint('[SYNC] Setting locale=${cloudSettings['locale']}');
        mainPageSettings.setLocale(cloudSettings['locale'] as String);
      }
      if (cloudSettings['songBookFile'] != null) {
        songBookSettings.setSongBookFile(cloudSettings['songBookFile'] as String);
      }
      if (cloudSettings['sortOrder'] != null) {
        prefs.setString('sortOrder', cloudSettings['sortOrder'] as String);
      }
      if (cloudSettings['searchBy'] != null) {
        prefs.setString('searchBy', cloudSettings['searchBy'] as String);
      }
      debugPrint('[SYNC] Cloud settings applied. isDarkMode now=${themeSettings.isDarkMode}, locale=${mainPageSettings.getLocale}');
    } else {
      // No cloud settings — first sign-in, push local settings to seed cloud
      String songBookFile = prefs.getString('songBookFile') ??
          'CityTabernacleBulawayo_Bulawayo_Zimbabwe';
      await SyncService.pushSettings(
        fontSize: songSettings.fontSize,
        displayKey: songSettings.displayKey,
        displaySongNumber: songSettings.displaySongNumber,
        isDarkMode: themeSettings.isDarkMode,
        songBookFile: songBookFile,
        locale: mainPageSettings.getLocale,
        sortOrder: prefs.getString('sortOrder'),
        searchBy: prefs.getString('searchBy'),
      );
    }

    // Pull cloud collections and merge into local DB
    final cloudCollections = await SyncService.pullCollections();
    if (cloudCollections != null) {
      final pulledCollections = cloudCollections['collections'];
      final pulledSongs = cloudCollections['collectionSongs'];
      if (pulledCollections != null) {
        for (var collection in pulledCollections) {
          if (!collectionsData.collections.any((c) => c.id == collection.id)) {
            await collectionsData.addCollection(collection);
          }
        }
      }
      if (pulledSongs != null) {
        for (var song in pulledSongs) {
          if (!collectionsData.collectionSongs.any((s) => s.id == song.id)) {
            await collectionsData.addCollectionSong(song);
          }
        }
      }
    }

    // Push local collections to cloud (merge)
    await SyncService.pushAllCollections(
      collectionsData.collections,
      collectionsData.collectionSongs,
    );
    debugPrint('[SYNC] _syncAfterSignIn END');
  }
}

class _SignedInView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) => Consumer<MainPageSettings>(
        builder: (context, mainPageSettings, child) => Localizations.override(
          context: context,
          locale: Locale(mainPageSettings.getLocale),
          child: Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.accountPageTitle),
              scrolledUnderElevation: 4,
            ),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: MediaQuery.of(context).size.width > 600
                      ? const EdgeInsets.fromLTRB(80, 20, 80, 40)
                      : const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (auth.photoUrl != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(auth.photoUrl!),
                        )
                      else
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Styles.themeColor,
                          child: Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        auth.displayName ?? AppLocalizations.of(context)!.accountUserFallback,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.cloud_done, color: Styles.themeColor, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.accountSyncingEnabled,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Styles.themeColor),
                      ),
                      const SizedBox(height: 32),
                      // Manual sync button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _manualSync(context),
                          icon: const Icon(Icons.sync),
                          label: Text(AppLocalizations.of(context)!.accountSyncNow),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleSignOut(context),
                          icon: const Icon(Icons.logout),
                          label: Text(AppLocalizations.of(context)!.accountSignOut),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _manualSync(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final syncComplete = l10n.accountSyncComplete;
    final syncFailed = l10n.accountSyncFailed;
    final songSettings = context.read<SongSettings>();
    final themeSettings = context.read<ThemeSettings>();
    final mainPageSettings = context.read<MainPageSettings>();
    final collectionsData = context.read<CollectionsData>();
    final prefs = await SharedPreferences.getInstance();
    final scaffold = ScaffoldMessenger.of(context);

    String songBookFile = prefs.getString('songBookFile') ??
        'CityTabernacleBulawayo_Bulawayo_Zimbabwe';

    AnalyticsService.instance.trackManualSync();
    final result = await SyncService.fullSync(
      fontSize: songSettings.fontSize,
      displayKey: songSettings.displayKey,
      displaySongNumber: songSettings.displaySongNumber,
      isDarkMode: themeSettings.isDarkMode,
      songBookFile: songBookFile,
      locale: mainPageSettings.getLocale,
      sortOrder: prefs.getString('sortOrder'),
      searchBy: prefs.getString('searchBy'),
      collections: collectionsData.collections,
      collectionSongs: collectionsData.collectionSongs,
    );

    if (result != null) {
      final settings = result['settings'] as Map<String, dynamic>?;
      if (settings != null) {
        if (settings['fontSize'] != null) {
          songSettings.setFontSize((settings['fontSize'] as num).toDouble());
        }
        if (settings['displayKey'] != null) {
          songSettings.setDisplayKey(settings['displayKey'] as bool);
        }
        if (settings['displaySongNumber'] != null) {
          songSettings.setDisplaySongNumber(settings['displaySongNumber'] as bool);
        }
        if (settings['isDarkMode'] != null) {
          themeSettings.setIsDarkMode(settings['isDarkMode'] as bool);
        }
        if (settings['locale'] != null) {
          mainPageSettings.setLocale(settings['locale'] as String);
        }
        if (settings['songBookFile'] != null) {
          prefs.setString('songBookFile', settings['songBookFile'] as String);
        }
      }

      final pulledCollections = result['collections'];
      final pulledSongs = result['collectionSongs'];
      if (pulledCollections != null) {
        for (var collection in pulledCollections) {
          if (!collectionsData.collections.any((c) => c.id == collection.id)) {
            await collectionsData.addCollection(collection);
          }
        }
      }
      if (pulledSongs != null) {
        for (var song in pulledSongs) {
          if (!collectionsData.collectionSongs.any((s) => s.id == song.id)) {
            await collectionsData.addCollectionSong(song);
          }
        }
      }
    }

    scaffold.showSnackBar(
      SnackBar(
        content: Text(result != null ? syncComplete : syncFailed),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.signOut();
    AnalyticsService.instance.trackSignOut();
    if (context.mounted) Navigator.of(context).pop();
  }
}
