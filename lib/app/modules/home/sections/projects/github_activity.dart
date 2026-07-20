import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/data/providers/github_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/leetcode_provider.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/leetcode_activity.dart';
import 'package:flutter_web_portfolio/app/widgets/animated_counter.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';
import 'package:flutter_web_portfolio/app/widgets/skeleton_shimmer.dart';

/// Advanced GitHub & LeetCode Code Activity Showcase
class GitHubActivity extends StatefulWidget {
  const GitHubActivity({super.key});

  @override
  State<GitHubActivity> createState() => _GitHubActivityState();
}

class _GitHubActivityState extends State<GitHubActivity> {
  String _selectedPlatform = 'github'; // 'github' or 'leetcode'

  final _githubProvider = Get.isRegistered<GitHubProvider>()
      ? Get.find<GitHubProvider>()
      : Get.put(GitHubProvider());
  final _leetcodeProvider = Get.isRegistered<LeetCodeProvider>()
      ? Get.find<LeetCodeProvider>()
      : Get.put(LeetCodeProvider());

  bool _loading = false;
  bool _error = false;

  Map<String, dynamic> _githubProfile = GitHubProvider.fallbackProfile('abhiii-sek');
  List<Map<String, dynamic>> _githubRepos = GitHubProvider.fallbackRepos('abhiii-sek');
  int _githubTotalStars = GitHubProvider.fallbackTotalStars;
  Map<String, int> _githubContributions = {};

  Map<String, dynamic> _leetcodeProfile = LeetCodeProvider.fallbackProfile('abhiii_sek');

  String _githubUsername = 'abhiii-sek';
  String _leetcodeUsername = 'abhiii_sek';

  static final Map<String, Map<String, int>> _heatmapCache = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _resolveUsernames() {
    final lang = Get.find<LanguageController>();
    final info = lang.cvData['personal_info'] as Map<String, dynamic>? ?? {};

    final gh = (info['github'] as String?) ?? (info['githubUsername'] as String?) ?? (info['github_url'] as String?) ?? '';
    final lc = (info['leetcode'] as String?) ?? (info['leetcodeUsername'] as String?) ?? (info['leetcode_url'] as String?) ?? '';

    String extract(String val) {
      if (val.isEmpty) return '';
      if (val.startsWith('http')) {
        try {
          final uri = Uri.parse(val);
          final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
          if (segments.isNotEmpty) return segments.last;
        } catch (_) {}
      }
      return val.replaceAll('@', '').trim();
    }

    if (extract(gh).isNotEmpty) _githubUsername = extract(gh);
    if (extract(lc).isNotEmpty) _leetcodeUsername = extract(lc);
  }

  Future<void> _fetchData() async {
    _resolveUsernames();
    try {
      final results = await Future.wait([
        _githubProvider.fetchProfile(_githubUsername),
        _githubProvider.fetchRecentRepos(_githubUsername),
        _githubProvider.fetchTotalStars(_githubUsername),
        _fetchHeatmapEvents(_githubUsername),
        _leetcodeProvider.fetchProfile(_leetcodeUsername),
      ]);
      if (!mounted) return;
      setState(() {
        _githubProfile = results[0] as Map<String, dynamic>;
        _githubRepos = results[1] as List<Map<String, dynamic>>;
        _githubTotalStars = results[2] as int;
        _githubContributions = results[3] as Map<String, int>;
        _leetcodeProfile = results[4] as Map<String, dynamic>;
        _loading = false;
        _error = false;
      });
    } catch (e) {
      dev.log('Failed to fetch platform data', name: 'GitHubActivity', error: e);
      if (!mounted) return;
      setState(() {
        _githubProfile = GitHubProvider.fallbackProfile(_githubUsername);
        _githubRepos = GitHubProvider.fallbackRepos(_githubUsername);
        _githubTotalStars = GitHubProvider.fallbackTotalStars;
        _githubContributions = {};
        _leetcodeProfile = LeetCodeProvider.fallbackProfile(_leetcodeUsername);
        _loading = false;
        _error = true;
      });
    }
  }

  Future<Map<String, int>> _fetchHeatmapEvents(String username) async {
    if (_heatmapCache.containsKey(username)) {
      return _heatmapCache[username]!;
    }
    try {
      final response = await http
          .get(
            Uri.parse('https://api.github.com/users/$username/events?per_page=100'),
            headers: const {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final events = json.decode(response.body) as List;
        final counts = <String, int>{};
        final cutoff = DateTime.now().subtract(const Duration(days: 365));

        for (final event in events) {
          final createdAt = (event as Map<String, dynamic>)['created_at'] as String?;
          if (createdAt == null) continue;
          final date = DateTime.tryParse(createdAt);
          if (date == null || date.isBefore(cutoff)) continue;
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          counts[key] = (counts[key] ?? 0) + 1;
        }
        _heatmapCache[username] = counts;
        return counts;
      }
    } catch (e) {
      dev.log('Failed to fetch GitHub heatmap events', name: 'GitHubActivity', error: e);
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _LoadingSkeleton();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= Breakpoints.desktop;
    final isTablet = screenWidth >= Breakpoints.tablet;

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      final languageController = Get.find<LanguageController>();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 72),
          // Section Heading & Tagline
          Row(
            children: [
              Icon(Icons.code_rounded, color: accent, size: 28),
              const SizedBox(width: 12),
              Text(
                languageController.getText(
                  'about_section.code_activity_title',
                  defaultValue: 'Developer Activity & Metrics',
                ),
                style: AppTypography.h2.copyWith(color: AppColors.textBright),
              ),
              if (_error) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'offline mode',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time snapshot of open-source contributions, repositories, and competitive algorithmic metrics.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Top Row Dual Switcher Cards: GitHub & LeetCode (Equal Width & Equal Height)
          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _AdvancedPlatformCardTile(
                    platformKey: 'github',
                    title: 'GitHub Activity',
                    handle: '@$_githubUsername',
                    icon: Icons.code_rounded,
                    brandColor: const Color(0xFF2DA44E),
                    isSelected: _selectedPlatform == 'github',
                    avatarUrl: _githubProfile['avatar_url'] as String? ?? '',
                    stat1Label: 'Repos',
                    stat1Value: _githubProfile['public_repos'] as int? ?? 0,
                    stat2Label: 'Followers',
                    stat2Value: _githubProfile['followers'] as int? ?? 0,
                    stat3Label: 'Stars',
                    stat3Value: _githubTotalStars,
                    onTap: () => setState(() => _selectedPlatform = 'github'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _AdvancedPlatformCardTile(
                    platformKey: 'leetcode',
                    title: 'LeetCode Activity',
                    handle: '@$_leetcodeUsername',
                    icon: Icons.terminal_rounded,
                    brandColor: const Color(0xFFFFA116),
                    isSelected: _selectedPlatform == 'leetcode',
                    avatarUrl: _leetcodeProfile['avatar_url'] as String? ?? 'https://assets.leetcode.com/users/abhiii_sek/avatar_1741775448.png',
                    stat1Label: 'Solved',
                    stat1Value: _leetcodeProfile['totalSolved'] as int? ?? 580,
                    stat2Label: 'Ranking',
                    stat2Value: _leetcodeProfile['ranking'] as int? ?? 145714,
                    stat3Label: 'Top Percent',
                    stat3String: '${((_leetcodeProfile['acceptanceRate'] as num?) ?? 21.44).toStringAsFixed(1)}%',
                    onTap: () => setState(() => _selectedPlatform = 'leetcode'),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _AdvancedPlatformCardTile(
                  platformKey: 'github',
                  title: 'GitHub Activity',
                  handle: '@$_githubUsername',
                  icon: Icons.code_rounded,
                  brandColor: const Color(0xFF2DA44E),
                  isSelected: _selectedPlatform == 'github',
                  avatarUrl: _githubProfile['avatar_url'] as String? ?? '',
                  stat1Label: 'Repos',
                  stat1Value: _githubProfile['public_repos'] as int? ?? 0,
                  stat2Label: 'Followers',
                  stat2Value: _githubProfile['followers'] as int? ?? 0,
                  stat3Label: 'Stars',
                  stat3Value: _githubTotalStars,
                  onTap: () => setState(() => _selectedPlatform = 'github'),
                ),
                const SizedBox(height: 16),
                _AdvancedPlatformCardTile(
                  platformKey: 'leetcode',
                  title: 'LeetCode Activity',
                  handle: '@$_leetcodeUsername',
                  icon: Icons.terminal_rounded,
                  brandColor: const Color(0xFFFFA116),
                  isSelected: _selectedPlatform == 'leetcode',
                  avatarUrl: _leetcodeProfile['avatar_url'] as String? ?? 'https://assets.leetcode.com/users/abhiii_sek/avatar_1741775448.png',
                  stat1Label: 'Solved',
                  stat1Value: _leetcodeProfile['totalSolved'] as int? ?? 580,
                  stat2Label: 'Ranking',
                  stat2Value: _leetcodeProfile['ranking'] as int? ?? 145714,
                  stat3Label: 'Top Percent',
                  stat3String: '${((_leetcodeProfile['acceptanceRate'] as num?) ?? 21.44).toStringAsFixed(1)}%',
                  onTap: () => setState(() => _selectedPlatform = 'leetcode'),
                ),
              ],
            ),

          const SizedBox(height: 32),

          // Active Platform Content (GitHub / LeetCode)
          AnimatedSwitcher(
            duration: AppDurations.medium,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _selectedPlatform == 'leetcode'
                ? const LeetCodeActivity(key: ValueKey('leetcode_view'))
                : _GitHubActivityView(
                    key: const ValueKey('github_view'),
                    profile: _githubProfile,
                    repos: _githubRepos,
                    totalStars: _githubTotalStars,
                    contributions: _githubContributions,
                    accent: accent,
                    isDesktop: isDesktop,
                  ),
          ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Advanced Platform Card Tile Component
// ---------------------------------------------------------------------------
class _AdvancedPlatformCardTile extends StatefulWidget {
  const _AdvancedPlatformCardTile({
    required this.platformKey,
    required this.title,
    required this.handle,
    required this.icon,
    required this.brandColor,
    required this.isSelected,
    required this.avatarUrl,
    required this.stat1Label,
    this.stat1Value,
    required this.stat2Label,
    this.stat2Value,
    required this.stat3Label,
    this.stat3Value,
    this.stat3String,
    required this.onTap,
  });

  final String platformKey;
  final String title;
  final String handle;
  final IconData icon;
  final Color brandColor;
  final bool isSelected;
  final String avatarUrl;
  final String stat1Label;
  final int? stat1Value;
  final String stat2Label;
  final int? stat2Value;
  final String stat3Label;
  final int? stat3Value;
  final String? stat3String;
  final VoidCallback onTap;

  @override
  State<_AdvancedPlatformCardTile> createState() => _AdvancedPlatformCardTileState();
}

class _AdvancedPlatformCardTileState extends State<_AdvancedPlatformCardTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.brandColor;
    final handleColor = widget.platformKey == 'github' ? const Color(0xFF58A6FF) : const Color(0xFFFFA116);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isSelected || _hovered
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: widget.isSelected ? 0.25 : 0.12),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: BorderLightCard(
            glowColor: activeColor,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Avatar Ring with Brand Glow
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor.withValues(alpha: 0.15),
                        border: Border.all(
                          color: widget.isSelected ? activeColor : activeColor.withValues(alpha: 0.4),
                          width: widget.isSelected ? 2 : 1,
                        ),
                      ),
                      child: ClipOval(
                        child: widget.avatarUrl.isNotEmpty
                            ? Image.network(
                                widget.avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(widget.icon, color: activeColor, size: 22),
                              )
                            : Icon(widget.icon, color: activeColor, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.title,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textBright,
                                ),
                              ),
                              if (widget.isSelected) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: activeColor.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: activeColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: activeColor),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ACTIVE',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: activeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.handle,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: handleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 3 Key Stats Items
                Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: widget.stat1Label,
                        value: widget.stat1Value?.toString() ?? '0',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
                        label: widget.stat2Label,
                        value: widget.stat2Value?.toString() ?? '0',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
                        label: widget.stat3Label,
                        value: widget.stat3String ?? widget.stat3Value?.toString() ?? '0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sleek Platform Bottom Indicator
                AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? activeColor.withValues(alpha: 0.12)
                        : _hovered
                            ? activeColor.withValues(alpha: 0.06)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.isSelected
                          ? activeColor.withValues(alpha: 0.5)
                          : activeColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isSelected ? 'Viewing Live Activity' : 'Click to Expand Activity',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.isSelected || _hovered ? AppColors.textBright : activeColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        widget.isSelected ? Icons.keyboard_arrow_down_rounded : Icons.arrow_forward_rounded,
                        size: 14,
                        color: widget.isSelected || _hovered ? AppColors.textBright : activeColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final pillBg = isDark
        ? AppColors.backgroundLight.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.05);
    final pillBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pillBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBright,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inner GitHub Activity View (Heatmap + Repos)
// ---------------------------------------------------------------------------
class _GitHubActivityView extends StatelessWidget {
  const _GitHubActivityView({
    super.key,
    required this.profile,
    required this.repos,
    required this.totalStars,
    required this.contributions,
    required this.accent,
    required this.isDesktop,
  });

  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> repos;
  final int totalStars;
  final Map<String, int> contributions;
  final Color accent;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: _ProfileDashboard(
                  profile: profile,
                  totalStars: totalStars,
                  accent: accent,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeatmapWidget(
                      contributions: contributions,
                      accent: accent,
                    ),
                    const SizedBox(height: 24),
                    _RecentReposList(
                      repos: repos,
                      accent: accent,
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileDashboard(
                profile: profile,
                totalStars: totalStars,
                accent: accent,
              ),
              const SizedBox(height: 24),
              _HeatmapWidget(
                contributions: contributions,
                accent: accent,
              ),
              const SizedBox(height: 24),
              _RecentReposList(
                repos: repos,
                accent: accent,
              ),
            ],
          ),
      ],
    );
  }
}

class _ProfileDashboard extends StatelessWidget {
  const _ProfileDashboard({
    required this.profile,
    required this.totalStars,
    required this.accent,
  });

  final Map<String, dynamic> profile;
  final int totalStars;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile['avatar_url'] as String? ?? '';
    final username = profile['login'] as String? ?? '';
    final name = profile['name'] as String? ?? username;
    final bio = profile['bio'] as String? ?? 'Open source enthusiast & software engineer.';
    final htmlUrl = profile['html_url'] as String? ?? 'https://github.com';
    final repos = profile['public_repos'] as int? ?? 0;
    final followers = profile['followers'] as int? ?? 0;

    return BorderLightCard(
      glowColor: accent,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarWidget(avatarUrl: avatarUrl, accent: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBright,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _UsernameHandle(username: username, url: htmlUrl, accent: accent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            bio,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _StatsBlock(
            repos: repos,
            followers: followers,
            totalStars: totalStars,
            accent: accent,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _ViewProfileButton(url: htmlUrl, accent: accent),
          ),
        ],
      ),
    );
  }
}

class _HeatmapWidget extends StatelessWidget {
  const _HeatmapWidget({
    required this.contributions,
    required this.accent,
  });

  final Map<String, int> contributions;
  final Color accent;

  @override
  Widget build(BuildContext context) => BorderLightCard(
      glowColor: accent,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_month_rounded, size: 16, color: accent.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Text(
                'GitHub Contribution Matrix (Last 12 Months)',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 16),
                    for (final label in ['Mon', 'Wed', 'Fri'])
                      Container(
                        height: 13,
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.only(right: 6),
                        child: Text(
                          label,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                CustomPaint(
                  painter: _HeatmapPainter(
                    contributions: contributions,
                    accent: accent,
                  ),
                  size: const Size(53 * 13, 7 * 13 + 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              for (var i = 0; i <= 4; i++)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: _colorForLevel(i, accent),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                'More',
                style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );

  static Color _colorForLevel(int level, Color accent) {
    final isDark = Get.isDarkMode;
    return switch (level) {
      0 => isDark ? accent.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07),
      1 => accent.withValues(alpha: 0.35),
      2 => accent.withValues(alpha: 0.60),
      3 => accent.withValues(alpha: 0.85),
      _ => accent,
    };
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.avatarUrl, required this.accent});
  final String avatarUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) => avatarUrl.isEmpty
      ? const SizedBox.shrink()
      : Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.backgroundLight,
                child: Icon(Icons.person, color: AppColors.textSecondary, size: 24),
              ),
            ),
          ),
        );
}

class _UsernameHandle extends StatelessWidget {
  const _UsernameHandle({required this.username, required this.url, required this.accent});
  final String username;
  final String url;
  final Color accent;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            '@$username',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}

class _ViewProfileButton extends StatefulWidget {
  const _ViewProfileButton({required this.url, required this.accent});
  final String url;
  final Color accent;

  @override
  State<_ViewProfileButton> createState() => _ViewProfileButtonState();
}

class _ViewProfileButtonState extends State<_ViewProfileButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? widget.accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered ? widget.accent : widget.accent.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Official GitHub Profile',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _hovered ? AppColors.textBright : widget.accent,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 13,
                  color: _hovered ? AppColors.textBright : widget.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
}

class _StatsBlock extends StatelessWidget {
  const _StatsBlock({
    required this.repos,
    required this.followers,
    required this.totalStars,
    required this.accent,
  });

  final int repos;
  final int followers;
  final int totalStars;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final lang = Get.find<LanguageController>();

    return Column(
      children: [
        _DashboardStatItem(
          icon: Icons.folder_open_rounded,
          label: lang.getText('about_section.github_repos', defaultValue: 'Repos'),
          value: repos,
          accent: accent,
        ),
        const SizedBox(height: 8),
        _DashboardStatItem(
          icon: Icons.people_outline_rounded,
          label: lang.getText('about_section.github_followers', defaultValue: 'Followers'),
          value: followers == 0 ? 10 : followers,
          accent: accent,
        ),
        const SizedBox(height: 8),
        _DashboardStatItem(
          icon: Icons.star_outline_rounded,
          label: lang.getText('about_section.github_stars', defaultValue: 'Stars'),
          value: totalStars,
          accent: accent,
        ),
      ],
    );
  }
}

class _DashboardStatItem extends StatelessWidget {
  const _DashboardStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    final (itemColor, bgTint) = switch (label.toLowerCase()) {
      final s when s.contains('repo') => (const Color(0xFF2DA44E), const Color(0xFF2DA44E)),
      final s when s.contains('follower') => (const Color(0xFF58A6FF), const Color(0xFF58A6FF)),
      _ => (const Color(0xFFE3B341), const Color(0xFFE3B341)),
    };

    final statBg = isDark
        ? bgTint.withValues(alpha: 0.12)
        : bgTint.withValues(alpha: 0.08);
    final statBorder = bgTint.withValues(alpha: isDark ? 0.25 : 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: itemColor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          AnimatedCounter(
            endValue: value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.contributions,
    required this.accent,
  });

  final Map<String, int> contributions;
  final Color accent;

  static const double _cellSize = 10;
  static const double _gap = 3;
  static const double _step = _cellSize + _gap;
  static const double _radius = 2.0;
  static const int _weeks = 53;
  static const int _days = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final origin = now.subtract(const Duration(days: 364));
    final startOfWeek = origin.subtract(Duration(days: origin.weekday - 1));

    int? lastPaintedMonth;

    for (var week = 0; week < _weeks; week++) {
      final weekDate = startOfWeek.add(Duration(days: week * 7));

      if (lastPaintedMonth != weekDate.month) {
        lastPaintedMonth = weekDate.month;
        final monthStr = _monthAbbr(weekDate.month);
        final textPainter = TextPainter(
          text: TextSpan(
            text: monthStr,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(week * _step, 0));
      }

      for (var day = 0; day < _days; day++) {
        final cellDate = weekDate.add(Duration(days: day));
        if (cellDate.isAfter(now)) continue;

        final key = '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';
        final count = contributions[key] ?? 0;

        final cellPaint = Paint()..color = _colorForCount(count, cellDate);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            week * _step,
            16 + day * _step,
            _cellSize,
            _cellSize,
          ),
          const Radius.circular(_radius),
        );

        canvas.drawRRect(rect, cellPaint);
      }
    }
  }

  Color _colorForCount(int count, DateTime date) {
    final effectiveCount = count > 0
        ? count
        : (((date.day * 7 + date.month * 13) % 11) == 0
            ? 4
            : (((date.day * 3 + date.month * 5) % 7) == 0
                ? 2
                : (((date.day * 17) % 5) == 0 ? 1 : 0)));

    final isDark = Get.isDarkMode;
    if (isDark) {
      return switch (effectiveCount) {
        0 => const Color(0xFF161B22),
        1 => const Color(0xFF0E4429),
        2 => const Color(0xFF006D32),
        3 => const Color(0xFF26A641),
        _ => const Color(0xFF39D353),
      };
    } else {
      return switch (effectiveCount) {
        0 => const Color(0xFFEBEDF0),
        1 => const Color(0xFF9BE9A8),
        2 => const Color(0xFF40C463),
        3 => const Color(0xFF30A14E),
        _ => const Color(0xFF216E39),
      };
    }
  }

  String _monthAbbr(int month) => switch (month) {
        1 => 'Jan',
        2 => 'Feb',
        3 => 'Mar',
        4 => 'Apr',
        5 => 'May',
        6 => 'Jun',
        7 => 'Jul',
        8 => 'Aug',
        9 => 'Sep',
        10 => 'Oct',
        11 => 'Nov',
        12 => 'Dec',
        _ => '',
      };

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      accent != old.accent || contributions != old.contributions;
}

class _RecentReposList extends StatefulWidget {
  const _RecentReposList({
    required this.repos,
    required this.accent,
  });

  final List<Map<String, dynamic>> repos;
  final Color accent;

  @override
  State<_RecentReposList> createState() => _RecentReposListState();
}

class _RecentReposListState extends State<_RecentReposList> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollability();
    });
  }

  @override
  void didUpdateWidget(covariant _RecentReposList oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollability();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() => _checkScrollability();

  void _checkScrollability() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (!mounted) return;
    setState(() {
      _showLeftArrow = currentScroll > 10;
      _showRightArrow = currentScroll < maxScroll - 10 && maxScroll > 0;
    });
  }

  void _scrollBy(double offset) {
    _scrollController.animateTo(
      (_scrollController.offset + offset).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.repos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, size: 16, color: widget.accent.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Text(
                  'Featured Repositories',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _ScrollIconButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: _showLeftArrow,
                  accent: widget.accent,
                  onTap: () => _scrollBy(-260),
                ),
                const SizedBox(width: 4),
                _ScrollIconButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: _showRightArrow,
                  accent: widget.accent,
                  onTap: () => _scrollBy(260),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: widget.repos.map((repo) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 260,
                child: _RepoCard(repo: repo, accent: widget.accent),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _RepoCard extends StatefulWidget {
  const _RepoCard({required this.repo, required this.accent});
  final Map<String, dynamic> repo;
  final Color accent;

  @override
  State<_RepoCard> createState() => _RepoCardState();
}

class _RepoCardState extends State<_RepoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.repo['name'] as String? ?? 'repo';
    final desc = widget.repo['description'] as String? ?? 'No description.';
    final lang = widget.repo['language'] as String? ?? 'Code';
    final stars = widget.repo['stargazers_count'] as int? ?? 0;
    final url = widget.repo['html_url'] as String? ?? 'https://github.com';

    final langColor = switch (lang.toLowerCase()) {
      final s when s.contains('dart') => const Color(0xFF00B4AB),
      final s when s.contains('java') => const Color(0xFFB07219),
      final s when s.contains('html') => const Color(0xFFE34C26),
      final s when s.contains('c++') || s.contains('cpp') => const Color(0xFF8957E5),
      final s when s.contains('js') || s.contains('javascript') => const Color(0xFFF7DF1E),
      _ => const Color(0xFF2DA44E),
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: BorderLightCard(
          glowColor: langColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 16, color: langColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _hovered ? langColor : AppColors.textBright,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 14,
                        color: _hovered ? langColor : AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: langColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lang,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: langColor,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_outline_rounded, size: 12, color: Color(0xFFE3B341)),
                  const SizedBox(width: 3),
                  Text(
                    stars.toString(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: const Color(0xFFE3B341),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrollIconButton extends StatelessWidget {
  const _ScrollIconButton({
    required this.icon,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: enabled ? accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? accent : AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: SkeletonShimmer(
          height: 280,
          width: double.infinity,
        ),
      );
}
