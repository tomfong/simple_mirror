import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _appSettingsChannel = MethodChannel('simple_mirror/app_settings');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SimpleMirrorApp());
}

enum AppLanguage { english, chineseTraditional, chineseHongKong }

enum AppTheme { light, dark, black }

class SimpleMirrorApp extends StatefulWidget {
  const SimpleMirrorApp({super.key});

  @override
  State<SimpleMirrorApp> createState() => _SimpleMirrorAppState();
}

class _SimpleMirrorAppState extends State<SimpleMirrorApp> {
  AppLanguage _language = AppLanguage.english;
  AppTheme _theme = AppTheme.dark;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSettings());
  }

  Future<void> _restoreSettings() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _language =
            appLanguageFromName(preferences.getString('language')) ??
            appLanguageForDeviceLocale(
              WidgetsBinding.instance.platformDispatcher.locale,
            );
        _theme = AppTheme.values.firstWhere(
          (value) => value.name == preferences.getString('theme'),
          orElse: () => AppTheme.dark,
        );
      });
    } catch (_) {}
  }

  Future<void> _setLanguage(AppLanguage language) async {
    setState(() => _language = language);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('language', language.name);
    } catch (_) {}
  }

  Future<void> _setTheme(AppTheme theme) async {
    setState(() => _theme = theme);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('theme', theme.name);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final strings = MirrorStrings(_language);
    return MaterialApp(
      title: strings.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(_theme),
      home: MirrorPage(
        strings: strings,
        language: _language,
        theme: _theme,
        onLanguageChanged: _setLanguage,
        onThemeChanged: _setTheme,
      ),
    );
  }
}

AppLanguage? appLanguageFromName(String? name) {
  for (final language in AppLanguage.values) {
    if (language.name == name) return language;
  }
  return null;
}

AppLanguage appLanguageForDeviceLocale(Locale locale) {
  final languageCode = locale.languageCode.toLowerCase();
  final countryCode = locale.countryCode?.toUpperCase();
  if (languageCode == 'yue' || (languageCode == 'zh' && countryCode == 'HK')) {
    return AppLanguage.chineseHongKong;
  }
  if (languageCode == 'zh') return AppLanguage.chineseTraditional;
  return AppLanguage.english;
}

ThemeData _buildTheme(AppTheme appTheme) {
  final brightness = appTheme == AppTheme.light
      ? Brightness.light
      : Brightness.dark;
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xff00a8a8),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
    scaffoldBackgroundColor: _scaffoldColor(appTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: appTheme == AppTheme.black
          ? Colors.black
          : const Color(0xff252525),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 24),
    ),
  );
}

Color _scaffoldColor(AppTheme theme) {
  switch (theme) {
    case AppTheme.light:
      return const Color(0xfffafafa);
    case AppTheme.dark:
      return const Color(0xff121212);
    case AppTheme.black:
      return Colors.black;
  }
}

class MirrorPage extends StatefulWidget {
  const MirrorPage({
    super.key,
    required this.strings,
    required this.language,
    required this.theme,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });

  final MirrorStrings strings;
  final AppLanguage language;
  final AppTheme theme;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<AppTheme> onThemeChanged;

  @override
  State<MirrorPage> createState() => _MirrorPageState();
}

class _MirrorPageState extends State<MirrorPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  String? _cameraError;
  bool _isCameraActive = true;
  bool _isCameraStarting = false;
  bool _retryCameraWhenReady = false;
  bool _isOpeningSettings = false;
  bool _isFlipped = true;
  bool _isCameraPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startCamera());
  }

  Future<void> _startCamera() async {
    if (!_isCameraActive || _cameraController?.value.isInitialized == true) {
      return;
    }
    if (_isCameraStarting) {
      _retryCameraWhenReady = true;
      return;
    }
    _isCameraStarting = true;
    try {
      final cameras = await availableCameras();
      if (!_isCameraActive) return;
      final frontCameras = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      final selectedCamera = frontCameras.isNotEmpty
          ? frontCameras.first
          : cameras.first;
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted || !_isCameraActive) {
        await controller.dispose();
        return;
      }
      await _cameraController?.dispose();
      setState(() {
        _cameraController = controller;
        _cameraError = null;
        _isCameraPermissionDenied = false;
      });
    } on CameraException catch (error) {
      if (mounted && _isCameraActive) {
        setState(() {
          _cameraError = error.description ?? error.code;
          _isCameraPermissionDenied = isCameraPermissionDenied(error.code);
        });
      }
    } catch (_) {
      if (mounted && _isCameraActive) {
        setState(() {
          _cameraError = widget.strings.cameraUnavailable;
          _isCameraPermissionDenied = false;
        });
      }
    } finally {
      _isCameraStarting = false;
      if (_retryCameraWhenReady) {
        _retryCameraWhenReady = false;
        if (mounted && _isCameraActive) {
          unawaited(_startCamera());
        }
      }
    }
  }

  Future<void> _stopCamera() async {
    _isCameraActive = false;
    _retryCameraWhenReady = false;
    final controller = _cameraController;
    if (controller == null) return;
    setState(() => _cameraController = null);
    await controller.dispose();
  }

  Future<void> _openSettings() async {
    if (_isOpeningSettings) return;
    _isOpeningSettings = true;
    unawaited(_stopCamera());
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SettingsPage(
            strings: widget.strings,
            language: widget.language,
            theme: widget.theme,
            onLanguageChanged: widget.onLanguageChanged,
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
      );
    } finally {
      if (!mounted) return;
      _isOpeningSettings = false;
      _isCameraActive = true;
      unawaited(_startCamera());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      unawaited(_stopCamera());
    } else if (state == AppLifecycleState.resumed) {
      _isCameraActive = true;
      unawaited(_restartCameraAfterResume());
    }
  }

  Future<void> _restartCameraAfterResume() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted && _isCameraActive) {
      await _startCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isCameraActive = false;
    _retryCameraWhenReady = false;
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CameraPreview(
            controller: _cameraController,
            isFlipped: _isFlipped,
            error: _cameraError,
          ),
          SafeArea(
            child: Column(
              children: [
                _MirrorToolbar(
                  title: widget.strings.appName,
                  infoTooltip: widget.strings.about,
                  onInfoPressed: () => unawaited(_openSettings()),
                ),
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _cameraController == null || _isCameraPermissionDenied
                            ? widget.strings.cameraPermissionRequired
                            : _isFlipped
                            ? widget.strings.flippedHint
                            : widget.strings.mirrorHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: _OverlayIconButton(
                        icon: _isFlipped ? Icons.flip : Icons.flip,
                        tooltip: widget.strings.flipHorizontally,
                        onPressed: () =>
                            setState(() => _isFlipped = !_isFlipped),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool isCameraPermissionDenied(String errorCode, [String? description]) {
  const knownCodes = {
    'CameraAccessDenied',
    'CameraAccessDeniedWithoutPrompt',
    'CameraAccessRestricted',
  };
  if (knownCodes.contains(errorCode)) return true;

  final errorDetails = '$errorCode ${description ?? ''}'.toLowerCase();
  final isPermissionContext =
      errorDetails.contains('permission') ||
      errorDetails.contains('camera access');
  return isPermissionContext &&
      (errorDetails.contains('denied') ||
          errorDetails.contains('restricted') ||
          errorDetails.contains('not authorized'));
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({
    required this.controller,
    required this.isFlipped,
    required this.error,
  });

  final CameraController? controller;
  final bool isFlipped;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (controller?.value.isInitialized == true) {
      return Center(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(isFlipped ? -1 : 1, 1, 1),
          child: CameraPreview(controller!),
        ),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: error == null
            ? const CircularProgressIndicator(color: Colors.white70)
            : Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
      ),
    );
  }
}

class _MirrorToolbar extends StatelessWidget {
  const _MirrorToolbar({
    required this.title,
    required this.infoTooltip,
    required this.onInfoPressed,
  });

  final String title;
  final String infoTooltip;
  final VoidCallback onInfoPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  shadows: const [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 64,
                    offset: Offset(0, 0.1),
                  ),
                ],
              ),
              child: IconButton(
                tooltip: infoTooltip,
                onPressed: onInfoPressed,
                color: Colors.white70,
                icon: const Icon(Icons.info_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        iconSize: 30,
        padding: const EdgeInsets.all(16),
        icon: Icon(icon),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.strings,
    required this.language,
    required this.theme,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });

  final MirrorStrings strings;
  final AppLanguage language;
  final AppTheme theme;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<AppTheme> onThemeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppLanguage _language = widget.language;
  late AppTheme _theme = widget.theme;

  MirrorStrings get _strings => MirrorStrings(_language);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_strings.settings)),
      body: ListView(
        children: [
          _SectionHeader(_strings.about),
          _SettingsTile(
            icon: Icons.info_outline,
            title: _strings.aboutSimpleMirror,
            onTap: () => _showAboutDialog(context),
          ),
          _SectionHeader(_strings.appearance),
          _SettingsTile(
            icon: Icons.language,
            title: _strings.languageTitle,
            subtitle: _strings.languageName(_language),
            onTap: _selectLanguage,
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: _strings.colorTheme,
            subtitle: _strings.themeName(_theme),
            onTap: _selectTheme,
          ),
          _SectionHeader(_strings.other),
          _SettingsTile(
            icon: Icons.camera_alt_outlined,
            title: _strings.appPermissions,
            onTap: () => _showPermissionDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _selectLanguage() async {
    final selected = await _showChoiceDialog<AppLanguage>(
      context: context,
      title: _strings.languageTitle,
      value: _language,
      values: AppLanguage.values,
      label: _strings.languageName,
    );
    if (selected == null) return;
    setState(() => _language = selected);
    widget.onLanguageChanged(selected);
  }

  Future<void> _selectTheme() async {
    final selected = await _showChoiceDialog<AppTheme>(
      context: context,
      title: _strings.colorTheme,
      value: _theme,
      values: AppTheme.values,
      label: _strings.themeName,
    );
    if (selected == null) return;
    setState(() => _theme = selected);
    widget.onThemeChanged(selected);
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/icons/app-icon-nobg-1000.png',
            width: 56,
            height: 56,
          ),
        ),
        title: Text(_strings.aboutSimpleMirror),
        content: Text(_strings.aboutDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_strings.close),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              unawaited(_openGitHub());
            },
            icon: const Icon(Icons.open_in_new),
            label: Text(_strings.visitGitHub),
          ),
        ],
      ),
    );
  }

  Future<void> _openGitHub() {
    return launchUrl(
      Uri.parse('https://github.com/tomfong/simple_mirror'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_strings.appPermissions),
        content: Text(_strings.permissionDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_strings.close),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              unawaited(_openAppSettings());
            },
            icon: const Icon(Icons.settings_outlined),
            label: Text(_strings.openAppSettings),
          ),
        ],
      ),
    );
  }
}

Future<void> _openAppSettings() async {
  try {
    await _appSettingsChannel.invokeMethod<void>('openAppSettings');
  } on MissingPluginException {
    return;
  }
}

Future<T?> _showChoiceDialog<T>({
  required BuildContext context,
  required String title,
  required T value,
  required List<T> values,
  required String Function(T) label,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.only(top: 12),
      content: RadioGroup<T>(
        groupValue: value,
        onChanged: (selected) {
          if (selected != null) Navigator.pop(context, selected);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: values
              .map(
                (option) =>
                    RadioListTile<T>(value: option, title: Text(label(option))),
              )
              .toList(),
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class MirrorStrings {
  const MirrorStrings(this.language);

  final AppLanguage language;

  bool get _isChinese => language != AppLanguage.english;
  bool get _isHongKongChinese => language == AppLanguage.chineseHongKong;

  String get appName {
    switch (language) {
      case AppLanguage.english:
        return 'Simple Mirror';
      case AppLanguage.chineseTraditional:
        return '就是鏡';
      case AppLanguage.chineseHongKong:
        return '照下鏡';
    }
  }

  String get settings => _isChinese ? '設定' : 'Settings';
  String get about => _isChinese ? '關於' : 'About';
  String get appearance => _isChinese ? '外觀' : 'Appearance';
  String get other => _isChinese ? '其他' : 'Other';
  String get aboutSimpleMirror =>
      _isChinese ? '關於「$appName」' : 'About Simple Mirror';
  String get languageTitle => _isChinese ? '語言' : 'Language';
  String get colorTheme => _isChinese ? '色彩主題' : 'Color Theme';
  String get appPermissions => _isChinese ? '應用程式權限' : 'App Permissions';
  String get flipHorizontally => _isChinese ? '水平翻轉' : 'Flip Horizontally';
  String get flippedHint => _isHongKongChinese
      ? '人哋眼中嘅你'
      : _isChinese
      ? '別人在現實中看到的你'
      : 'A view of how other people see you in real life';
  String get mirrorHint => _isHongKongChinese
      ? '你照鏡望到嘅樣'
      : _isChinese
      ? '你在鏡子中的樣子'
      : 'A view of how you look in a mirror';
  String get close => _isChinese ? '關閉' : 'Close';
  String get openAppSettings => _isChinese ? '開啟 App 設定' : 'Open App Settings';
  String get visitGitHub => _isChinese ? '前往 GitHub' : 'Visit GitHub';
  String get cameraUnavailable => _isChinese
      ? '無法使用相機，請檢查相機權限。'
      : 'Camera unavailable. Check camera permission.';
  String get cameraPermissionRequired =>
      _isChinese ? '請先授權使用相機' : 'Please grant camera permission first';
  String get aboutDescription => _isHongKongChinese
      ? '由 Tom FONG 開發。\n\n等你睇到人哋眼中嘅自己。'
      : _isChinese
      ? '由 Tom FONG 開發。\n\n讓你看見別人眼中的自己。'
      : 'Developed by Tom FONG.\n\nSee yourself as others see you.';
  String get permissionDescription => _isChinese
      ? '$appName 只會要求相機權限，以顯示即時鏡面預覽。'
      : 'Simple Mirror only requests camera permission to show the live mirror preview.';

  String languageName(AppLanguage selected) {
    switch (selected) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.chineseTraditional:
        return '繁體中文';
      case AppLanguage.chineseHongKong:
        return '繁體中文（香港）';
    }
  }

  String themeName(AppTheme selected) {
    switch (selected) {
      case AppTheme.light:
        return _isChinese ? '淺色' : 'Light';
      case AppTheme.dark:
        return _isChinese ? '深色' : 'Dark';
      case AppTheme.black:
        return _isChinese ? '黑色' : 'Black';
    }
  }
}
