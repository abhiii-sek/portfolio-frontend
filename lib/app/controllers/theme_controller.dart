import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/utils/platform_helper.dart' as platform;

/// Controller managing application-wide ThemeMode state.
/// Reactively switches between light and dark themes and persists preference locally.
class ThemeController extends GetxController {
  final _storage = Get.find<ILocalStorageProvider>();
  final Rx<ThemeMode> themeMode = ThemeMode.light.obs; // Default to light

  @override
  void onInit() {
    super.onInit();
    final isDark = _storage.getBool('is_dark_mode') ?? false; // Default to light
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => themeMode.value == ThemeMode.dark;

  Future<void> toggleTheme() async {
    if (themeMode.value == ThemeMode.dark) {
      themeMode.value = ThemeMode.light;
      await _storage.setBool('is_dark_mode', false);
      Get.changeThemeMode(ThemeMode.light);
    } else {
      themeMode.value = ThemeMode.dark;
      await _storage.setBool('is_dark_mode', true);
      Get.changeThemeMode(ThemeMode.dark);
    }
    
    // Force SceneDirector to recalculate colors instantly
    if (Get.isRegistered<SceneDirector>()) {
      Get.find<SceneDirector>().recalculate();
    }

    // Trigger full page reload for complete theme rebuild
    platform.reloadPage();
  }
}
