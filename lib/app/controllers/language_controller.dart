import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;
import 'package:http/http.dart' as http;
import 'package:flutter_web_portfolio/app/core/constants/api_constants.dart';

/// LanguageController fetches the aggregated portfolio layout and data directly 
/// from the Spring Boot REST API, removing any static asset translation logic from the client.
class LanguageController extends GetxController {

  LanguageController();

  final Rx<String> _currentLanguage = 'en'.obs;
  String get currentLanguage => _currentLanguage.value;

  Locale get currentLocale => Locale(_currentLanguage.value);

  Map<String, String> get languageInfo => {
    'code': _currentLanguage.value,
    'name': 'English',
    'flag': '🇬🇧',
  };

  Map<String, String> get supportedLanguages => const {
    'en': 'English',
  };

  // Unified dynamic translations layout state
  final _translations = Rx<Map<String, dynamic>>({});

  Map<String, dynamic> get cvData => switch (_translations.value['cv_data']) {
    final Map<String, dynamic> data => data,
    _ => const <String, dynamic>{},
  };

  String get appName =>
      _translations.value['app_name']?.toString() ?? 'Abhishek Kumar Pal';

  /// Determines which sections are active and should be rendered in the UI
  List<String> get activeSections {
    final data = cvData;
    return [
      'home',
      if (data['personal_info'] is Map) 'about',
      if (data['experiences'] case final List l when l.isNotEmpty) 'experience',
      if (data['testimonials'] case final List l when l.isNotEmpty) 'testimonials',
      if (data['projects'] case final List l when l.isNotEmpty) 'projects',
      'contact',
    ];
  }

  /// Traverses a dot-separated string path in the active translations map 
  String getText(String key, {String defaultValue = ''}) {
    final parts = key.split('.');
    dynamic current = _translations.value;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return defaultValue;
      }
    }
    return current?.toString() ?? defaultValue;
  }

  @override
  void onInit() {
    super.onInit();
    loadPortfolioData();
  }

  Future<void> loadPortfolioData() async {
    await changeLanguage('en');
  }

  Future<void> changeLanguage(String languageCode) async {
    _currentLanguage.value = 'en';
    unawaited(Get.updateLocale(const Locale('en')));
    url_strategy.setHtmlLang('en');
    await _updateTranslations('en');
  }

  /// Performs HTTP GETs to query Spring Boot for the split page parts and aggregates them.
  Future<void> _updateTranslations(String languageCode) async {
    try {
      final endpoints = [
        'metadata',
        'personal-info',
        'experiences',
        'projects',
        'education',
        'skills',
        'testimonials',
      ];

      final responses = await Future.wait(
        endpoints.map((endpoint) => http
            .get(Uri.parse('${ApiConstants.baseUrl}/api/public/portfolio/$endpoint'))
            .timeout(const Duration(seconds: 15))
        ),
      );

      // Check if all requests succeeded (status code 200)
      for (var i = 0; i < responses.length; i++) {
        if (responses[i].statusCode != 200) {
          dev.log('Spring Boot backend returned status code: ${responses[i].statusCode} for endpoint ${endpoints[i]}', name: 'LanguageController');
          return;
        }
      }

      final metadata = json.decode(utf8.decode(responses[0].bodyBytes)) as Map<String, dynamic>;
      final personalInfo = json.decode(utf8.decode(responses[1].bodyBytes));
      final experiences = json.decode(utf8.decode(responses[2].bodyBytes));
      final projects = json.decode(utf8.decode(responses[3].bodyBytes));
      final education = json.decode(utf8.decode(responses[4].bodyBytes));
      final skills = json.decode(utf8.decode(responses[5].bodyBytes));
      final testimonials = json.decode(utf8.decode(responses[6].bodyBytes));

      final cvData = metadata['cv_data'] is Map
          ? Map<String, dynamic>.from(metadata['cv_data'] as Map)
          : <String, dynamic>{};
      cvData['personal_info'] = personalInfo;
      cvData['experiences'] = experiences;
      cvData['projects'] = projects;
      cvData['education'] = education;
      cvData['skills'] = skills;
      cvData['testimonials'] = testimonials;

      metadata['cv_data'] = cvData;
      _translations.value = metadata;
    } catch (e) {
      dev.log('Failed to fetch dynamic layout configuration from Spring backend', name: 'LanguageController', error: e);
    }
  }
}


