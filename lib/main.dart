import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/bindings/app_bindings.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_theme.dart';
import 'package:flutter_web_portfolio/app/routes/app_pages.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_interaction_wrapper.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/local_storage_provider.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Pre-initialize local storage to resolve analytical startup race conditions
      final localStorage = LocalStorageProvider();
      await localStorage.init();
      Get.put<ILocalStorageProvider>(localStorage, permanent: true);

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        dev.log('Flutter error', name: 'Main', error: details.exception);
      };

      AppBindings().dependencies();


      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );

      runApp(const MyApp());
    },
    (error, stack) {
      dev.log('Uncaught error', name: 'Main', error: error, stackTrace: stack);
    },
  );
}

/// Root application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<ILocalStorageProvider>();
    final isDark = storage.getBool('is_dark_mode') ?? false;

    return GetMaterialApp(
      title: 'Abhishek Kumar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      transitionDuration: const Duration(milliseconds: 400),
      getPages: AppPages.routes,
      unknownRoute: AppPages.unknownRoute,
      initialRoute: AppPages.initial,
      defaultTransition: Transition.fadeIn,
      builder: (context, child) {
        if (!kIsWeb) return child!;
        return MouseInteractionWrapper(child: child!);
      },
    );
  }
}
