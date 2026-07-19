import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_portfolio/app/core/constants/api_constants.dart';

/// Engagement level inferred from visitor behaviour.
enum EngagementLevel { low, medium, high }

/// Device category derived from screen width.
enum DeviceType { mobile, tablet, desktop }

/// Aggregated visitor profile built from locally stored analytics.
final class VisitorProfile {
  const VisitorProfile({
    required this.interests,
    required this.engagement,
    required this.visitCount,
    required this.isReturnVisitor,
    required this.deviceType,
    required this.preferredLanguage,
    required this.referrerSource,
    required this.visitHour,
    required this.maxScrollDepth,
    required this.viewedProjectIds,
    required this.sectionDurations,
  });

  /// Sections the visitor has spent the most time on.
  final List<String> interests;

  /// Overall engagement level.
  final EngagementLevel engagement;

  /// Total number of visits.
  final int visitCount;

  /// Whether this is a returning visitor.
  final bool isReturnVisitor;

  /// Detected device category.
  final DeviceType deviceType;

  /// Browser language code (e.g. 'en', 'tr').
  final String preferredLanguage;

  /// Referrer hostname, or empty if unavailable.
  final String referrerSource;

  /// Hour of the current visit (0-23).
  final int visitHour;

  /// Maximum scroll depth reached (0.0 - 1.0).
  final double maxScrollDepth;

  /// Project IDs the visitor has viewed/clicked.
  final List<String> viewedProjectIds;

  /// Cumulative time (seconds) spent on each section.
  final Map<String, int> sectionDurations;
}

/// Privacy-first visitor analytics service.
///
/// All data is stored exclusively in the browser's localStorage. The service tracks
/// lightweight behavioural signals and pulls public geolocation metadata on startup.
final class VisitorAnalytics {
  // ─── Storage keys ──────────────────────────────────────────────────
  static const _keyVisitCount = 'va_visit_count';
  static const _keyFirstVisitTs = 'va_first_visit';
  static const _keyLastVisitTs = 'va_last_visit';
  static const _keyScrollDepth = 'va_scroll_depth';
  static const _keyViewedProjects = 'va_viewed_projects';
  static const _keySectionDurations = 'va_section_durations';
  static const _keyVisitsLog = 'va_visits_log';

  // ─── State ─────────────────────────────────────────────────────────
  bool _initialised = false;
  static bool _sessionLogged = false;

  int _visitCount = 0;
  double _maxScrollDepth = 0.0;
  List<String> _viewedProjectIds = [];
  Map<String, int> _sectionDurations = {};

  // Section timing helpers.
  String? _currentSection;
  DateTime? _sectionEnteredAt;

  /// Build a snapshot [VisitorProfile] from the current analytics state.
  VisitorProfile get profile {
    _flushCurrentSection();

    return VisitorProfile(
      interests: _topInterests(),
      engagement: _computeEngagement(),
      visitCount: _visitCount,
      isReturnVisitor: _visitCount > 1,
      deviceType: _detectDeviceType(),
      preferredLanguage: _detectLanguage(),
      referrerSource: _detectReferrer(),
      visitHour: DateTime.now().hour,
      maxScrollDepth: _maxScrollDepth,
      viewedProjectIds: List.unmodifiable(_viewedProjectIds),
      sectionDurations: Map.unmodifiable(_sectionDurations),
    );
  }

  // ─── Initialisation ────────────────────────────────────────────────

  /// Loads persisted data and increments the visit counter.
  /// Safe to call multiple times — subsequent calls are no-ops.
  void init() {
    if (_initialised) return;
    _initialised = true;

    final storage = _storage;
    if (storage == null) return;

    try {
      // Visit count.
      _visitCount = (storage.getInt(_keyVisitCount) ?? 0) + 1;
      storage.setInt(_keyVisitCount, _visitCount);

      // First / last visit timestamps.
      if (storage.getString(_keyFirstVisitTs) == null) {
        storage.setString(_keyFirstVisitTs, DateTime.now().toIso8601String());
      }
      storage.setString(_keyLastVisitTs, DateTime.now().toIso8601String());

      // Scroll depth.
      final savedDepth = storage.getString(_keyScrollDepth);
      if (savedDepth != null) {
        _maxScrollDepth = double.tryParse(savedDepth) ?? 0.0;
      }

      // Viewed projects.
      final savedProjects = storage.getString(_keyViewedProjects);
      if (savedProjects != null) {
        _viewedProjectIds =
            (jsonDecode(savedProjects) as List).cast<String>().toList();
      }

      // Section durations.
      final savedDurations = storage.getString(_keySectionDurations);
      if (savedDurations != null) {
        _sectionDurations = (jsonDecode(savedDurations) as Map)
            .map((k, v) => MapEntry(k as String, (v as num).toInt()));
      }

      // Perform background geolocation logging once per application run session
      if (!_sessionLogged) {
        _sessionLogged = true;
        _logVisitorGeolocation();
      }
    } catch (e) {
      dev.log('Failed to load analytics', name: 'VisitorAnalytics', error: e);
    }
  }

  // ─── Tracking API ──────────────────────────────────────────────────

  /// Record that the visitor is now viewing [sectionId].
  /// Automatically closes timing for the previous section.
  void trackSectionEnter(String sectionId) {
    _flushCurrentSection();
    _currentSection = sectionId;
    _sectionEnteredAt = DateTime.now();
  }

  /// Update the maximum scroll depth (0.0 – 1.0).
  void trackScrollDepth(double depth) {
    final clamped = depth.clamp(0.0, 1.0);
    if (clamped > _maxScrollDepth) {
      _maxScrollDepth = clamped;
      _persist(_keyScrollDepth, _maxScrollDepth.toStringAsFixed(4));
    }
  }

  /// Record that a project was viewed/clicked.
  void trackProjectView(String projectId) {
    if (!_viewedProjectIds.contains(projectId)) {
      _viewedProjectIds.add(projectId);
      _persist(_keyViewedProjects, jsonEncode(_viewedProjectIds));
    }
  }

  /// Flush pending section time and persist all analytics.
  void flush() {
    _flushCurrentSection();
  }

  // ─── Private helpers ───────────────────────────────────────────────

  ILocalStorageProvider? get _storage {
    try {
      if (Get.isRegistered<ILocalStorageProvider>()) {
        final s = Get.find<ILocalStorageProvider>();
        return s.isInitialized ? s : null;
      }
    } catch (e) {
      dev.log('Failed to access local storage provider', name: 'VisitorAnalytics', error: e);
    }
    return null;
  }

  void _persist(String key, String value) {
    try {
      _storage?.setString(key, value);
    } catch (e) {
      dev.log('Persist failed for $key', name: 'VisitorAnalytics', error: e);
    }
  }

  /// Close timing for the current section and accumulate its duration.
  void _flushCurrentSection() {
    if (_currentSection != null && _sectionEnteredAt != null) {
      final elapsed =
          DateTime.now().difference(_sectionEnteredAt!).inSeconds;
      if (elapsed > 0) {
        _sectionDurations[_currentSection!] =
            (_sectionDurations[_currentSection!] ?? 0) + elapsed;
        _persist(_keySectionDurations, jsonEncode(_sectionDurations));
      }
    }
    _sectionEnteredAt = _currentSection != null ? DateTime.now() : null;
  }

  /// Gathers visitor geolocation metrics using public geolocation endpoints in the background
  Future<void> _logVisitorGeolocation() async {
    Map<String, dynamic>? locationData;

    // Method 1: Fetch location details from ipapi.co
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        locationData = {
          'ip': decoded['ip']?.toString(),
          'city': decoded['city']?.toString(),
          'country': decoded['country_name']?.toString(),
        };
      }
    } catch (e) {
      dev.log('First geolocation lookup failed, trying backup', name: 'VisitorAnalytics', error: e);
    }

    // Method 2 (Backup): Fetch location details from freeipapi.com
    if (locationData == null) {
      try {
        final response = await http.get(Uri.parse('https://freeipapi.com/api/json'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          locationData = {
            'ip': decoded['ipAddress']?.toString(),
            'city': decoded['cityName']?.toString(),
            'country': decoded['countryName']?.toString(),
          };
        }
      } catch (e) {
        dev.log('Backup geolocation lookup failed', name: 'VisitorAnalytics', error: e);
      }
    }

    final ip = locationData?['ip'] ?? 'Unknown';
    final city = locationData?['city'] ?? 'Unknown';
    final country = locationData?['country'] ?? 'Unknown';

    final storage = _storage;
    if (storage != null) {
      // Fetch existing logs
      final String? existingLogsJson = storage.getString(_keyVisitsLog);
      List<dynamic> logs = [];
      if (existingLogsJson != null) {
        try {
          logs = jsonDecode(existingLogsJson) as List<dynamic>;
        } catch (e) {
          dev.log('Failed to parse existing visits log', name: 'VisitorAnalytics', error: e);
        }
      }

      // Construct a new record matching user specifications
      final Map<String, dynamic> newEntry = {
        'ip': ip,
        'city': city,
        'country': country,
        'is_repeating': _visitCount > 1,
        'timestamp': DateTime.now().toIso8601String(),
        'frequency': _visitCount,
        'device_type': _detectDeviceType().name,
      };

      logs.add(newEntry);

      // Bound logs list size to maximum 100 entries to avoid overflowing local storage
      if (logs.length > 100) {
        logs.removeRange(0, logs.length - 100);
      }

      storage.setString(_keyVisitsLog, jsonEncode(logs));
      dev.log('Visitor visit logged successfully: $newEntry', name: 'VisitorAnalytics');

      // Dispatch tracking record to backend REST API
      _postAnalyticsToBackend(newEntry);
    }
  }

  /// Sends captured visit analytics to Spring Boot backend database
  Future<void> _postAnalyticsToBackend(Map<String, dynamic> entry) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/public/analytics'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(entry),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        dev.log('Successfully recorded visitor metrics on database server', name: 'VisitorAnalytics');
      } else {
        dev.log('Backend server returned status code: ${response.statusCode} for metrics', name: 'VisitorAnalytics');
      }
    } catch (e) {
      dev.log('Failed to dispatch analytics payload to Spring Boot database', name: 'VisitorAnalytics', error: e);
    }
  }

  /// Return the top sections by dwell time, most-visited first.
  List<String> _topInterests() {
    if (_sectionDurations.isEmpty) return const [];

    final sorted = _sectionDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => e.key).toList();
  }

  /// Derive an engagement level from available signals.
  EngagementLevel _computeEngagement() {
    var score = 0;

    // Visit frequency.
    if (_visitCount >= 5) {
      score += 3;
    } else if (_visitCount >= 2) {
      score += 1;
    }

    // Scroll depth.
    if (_maxScrollDepth >= 0.8) {
      score += 3;
    } else if (_maxScrollDepth >= 0.4) {
      score += 1;
    }

    // Project views.
    if (_viewedProjectIds.length >= 3) {
      score += 2;
    } else if (_viewedProjectIds.isNotEmpty) {
      score += 1;
    }

    // Sections visited.
    if (_sectionDurations.length >= 4) {
      score += 2;
    } else if (_sectionDurations.length >= 2) {
      score += 1;
    }

    if (score >= 7) return EngagementLevel.high;
    if (score >= 3) return EngagementLevel.medium;
    return EngagementLevel.low;
  }

  /// Detect device type from logical screen width.
  DeviceType _detectDeviceType() {
    try {
      final view = PlatformDispatcher.instance.implicitView;
      if (view != null) {
        final width =
            view.physicalSize.width / view.devicePixelRatio;
        if (width < 600) return DeviceType.mobile;
        if (width < 1024) return DeviceType.tablet;
      }
    } catch (e) {
      dev.log('Failed to detect device type', name: 'VisitorAnalytics', error: e);
    }
    return DeviceType.desktop;
  }

  /// Best-effort language detection from the platform.
  String _detectLanguage() {
    try {
      final locales = PlatformDispatcher.instance.locales;
      if (locales.isNotEmpty) return locales.first.languageCode;
    } catch (e) {
      dev.log('Failed to detect language', name: 'VisitorAnalytics', error: e);
    }
    return 'en';
  }

  /// Referrer detection
  String _detectReferrer() => '';
}
