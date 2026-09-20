// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_mirror/main.dart';

void main() {
  testWidgets('opens settings from the mirror screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SimpleMirrorApp());

    expect(find.text('Simple Mirror'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About Simple Mirror'), findsOneWidget);
    expect(find.text('More settings coming soon'), findsNothing);
  });

  test('uses the requested Traditional Chinese mirror copy', () {
    const strings = MirrorStrings(AppLanguage.chineseTraditional);

    expect(strings.appName, '就是鏡');
    expect(strings.languageName(AppLanguage.chineseTraditional), '繁體中文');
    expect(strings.appPermissions, '應用程式權限');
    expect(strings.flippedHint, '別人在現實中看到的你');
    expect(strings.mirrorHint, '你在鏡子中的樣子');
    expect(strings.cameraPermissionRequired, '請先授權使用相機');
  });

  test('uses Hong Kong app name for the Hong Kong Chinese option', () {
    const strings = MirrorStrings(AppLanguage.chineseHongKong);

    expect(strings.appName, '照下鏡');
    expect(strings.languageName(AppLanguage.chineseHongKong), '繁體中文（香港）');
    expect(strings.aboutSimpleMirror, '關於「照下鏡」');
    expect(strings.flippedHint, '人哋眼中嘅你');
    expect(strings.mirrorHint, '你照鏡望到嘅樣');
    expect(strings.aboutDescription, '由 Tom FONG 開發。\n\n等你睇到人哋眼中嘅自己。');
  });

  test('uses the requested app language for each device locale', () {
    expect(
      appLanguageForDeviceLocale(const Locale('zh', 'CN')),
      AppLanguage.chineseTraditional,
    );
    expect(
      appLanguageForDeviceLocale(const Locale('zh', 'HK')),
      AppLanguage.chineseHongKong,
    );
    expect(
      appLanguageForDeviceLocale(const Locale('zh', 'TW')),
      AppLanguage.chineseTraditional,
    );
    expect(
      appLanguageForDeviceLocale(const Locale('zh', 'MO')),
      AppLanguage.chineseTraditional,
    );
    expect(
      appLanguageForDeviceLocale(const Locale('zh', 'SG')),
      AppLanguage.chineseTraditional,
    );
    expect(
      appLanguageForDeviceLocale(const Locale('yue', 'CN')),
      AppLanguage.chineseHongKong,
    );
    expect(
      appLanguageForDeviceLocale(const Locale('en', 'US')),
      AppLanguage.english,
    );
  });

  test('keeps a saved language preference over the device default', () {
    expect(appLanguageFromName(AppLanguage.english.name), AppLanguage.english);
    expect(
      appLanguageFromName(AppLanguage.chineseTraditional.name),
      AppLanguage.chineseTraditional,
    );
    expect(
      appLanguageFromName(AppLanguage.chineseHongKong.name),
      AppLanguage.chineseHongKong,
    );
    expect(appLanguageFromName('unsupported'), isNull);
  });

  test('recognizes camera permission denial errors', () {
    expect(isCameraPermissionDenied('CameraAccessDenied'), isTrue);
    expect(isCameraPermissionDenied('CameraAccessDeniedWithoutPrompt'), isTrue);
    expect(isCameraPermissionDenied('CameraAccessRestricted'), isTrue);
    expect(
      isCameraPermissionDenied(
        'CameraError',
        'Camera permission was denied by the user.',
      ),
      isTrue,
    );
    expect(
      isCameraPermissionDenied(
        'CameraError',
        'Camera access is not authorized.',
      ),
      isTrue,
    );
    expect(isCameraPermissionDenied('NoCameraFound'), isFalse);
  });
}
