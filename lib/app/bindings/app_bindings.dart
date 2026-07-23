import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/personalization_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/data/providers/github_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';

/// AppBindings is the central dependency injection configuration class using GetX.
/// Registers all global controllers and backend API connectors at application startup.
class AppBindings extends Bindings {

  @override
  void dependencies() {
    _registerSyncDependencies();
  }

  /// Registers only necessary controllers and dynamic client models.
  void _registerSyncDependencies() {
    // 1. Initialize Local Storage Provider
    if (!Get.isRegistered<ILocalStorageProvider>()) {
      final localStorage = LocalStorageProvider();
      Get.put<ILocalStorageProvider>(localStorage, permanent: true);
      localStorage.init();
    }

    // 2. Register Language & Portfolio Controller
    // Since static files were removed, LanguageController handles querying and parsing the API directly.
    Get..put(LanguageController(), permanent: true)

    // 3. Register UI and Analytics Controllers

      ..put(ThemeController(), permanent: true)
      ..put(AppScrollController(), permanent: true)
      ..put(SceneDirector(), permanent: true)
      ..put(CursorController(), permanent: true)
      ..put(GitHubProvider(), permanent: true)
      ..put(PersonalizationController(), permanent: true);
  }
}
