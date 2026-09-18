import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glam/src/core/storage/settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsStorage> makeStorage({
    Map<String, Object> seed = const {},
  }) async {
    SharedPreferences.setMockInitialValues(seed);
    return SettingsStorage(await SharedPreferences.getInstance());
  }

  test('defaults to system theme', () async {
    final storage = await makeStorage();
    expect(storage.themeMode, ThemeMode.system);
  });

  test('persists theme mode', () async {
    final storage = await makeStorage();
    await storage.setThemeMode(ThemeMode.dark);
    expect(storage.themeMode, ThemeMode.dark);
  });

  test('reads persisted theme mode', () async {
    final storage = await makeStorage(seed: {'glam.theme_mode': 'light'});
    expect(storage.themeMode, ThemeMode.light);
  });

  test('codeWrap defaults false and persists', () async {
    final storage = await makeStorage();
    expect(storage.codeWrap, isFalse);
    await storage.setCodeWrap(true);
    expect(storage.codeWrap, isTrue);
  });

  test('locale defaults to system and persists', () async {
    final storage = await makeStorage();
    expect(storage.localeName, 'system');
    await storage.setLocaleName('zh');
    expect(storage.localeName, 'zh');
  });

  test('reads persisted locale', () async {
    final storage = await makeStorage(seed: {'glam.locale': 'en'});
    expect(storage.localeName, 'en');
  });
}
