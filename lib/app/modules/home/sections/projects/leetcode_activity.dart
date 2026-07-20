import 'dart:math' as math;
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/data/providers/leetcode_provider.dart';
import 'package:flutter_web_portfolio/app/widgets/animated_counter.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';
import 'package:flutter_web_portfolio/app/widgets/skeleton_shimmer.dart';

/// Advanced LeetCode Activity Section
class LeetCodeActivity extends StatefulWidget {
  const LeetCodeActivity({super.key});

  @override
  State<LeetCodeActivity> createState() => _LeetCodeActivityState();
}

class _LeetCodeActivityState extends State<LeetCodeActivity> {
  final _provider = Get.isRegistered<LeetCodeProvider>()
      ? Get.find<LeetCodeProvider>()
      : Get.put(LeetCodeProvider());

  bool _loading = false;
  Map<String, dynamic> _profile = LeetCodeProvider.fallbackProfile('abhiii_sek');
  List<Map<String, dynamic>> _submissions = LeetCodeProvider.fallbackSubmissions();
  String _username = 'abhiii_sek';

  static const Color leetCodeAmber = Color(0xFFFFA116);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String? _resolveUsername() {
    final lang = Get.find<LanguageController>();
    final info = lang.cvData['personal_info'] as Map<String, dynamic>?;
    final leetcode = (info?['leetcode'] as String?) ??
        (info?['leetcodeUsername'] as String?) ??
        (info?['leetcode_url'] as String?) ??
        (info?['leetcodeUrl'] as String?) ??
        (info?['leetcode_username'] as String?) ??
        '';
    if (leetcode.isEmpty) return null;
    if (leetcode.startsWith('http')) {
      try {
        final uri = Uri.parse(leetcode);
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          return segments.last;
        }
      } catch (_) {}
    }
    return leetcode.replaceAll('@', '').trim();
  }

  Future<void> _fetchData() async {
    _username = _resolveUsername() ?? _username;
    try {
      final results = await Future.wait([
        _provider.fetchProfile(_username),
        _provider.fetchRecentSubmissions(_username),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>;
        _submissions = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      dev.log('Failed to fetch LeetCode data', name: 'LeetCodeActivity', error: e);
      if (!mounted) return;
      setState(() {
        _profile = LeetCodeProvider.fallbackProfile(_username);
        _submissions = LeetCodeProvider.fallbackSubmissions();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _LoadingSkeleton();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= Breakpoints.tablet;

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: Advanced Problem Solving Dial & Tiers
                SizedBox(
                  width: 320,
                  child: _AdvancedLeetCodeProfileCard(
                    profile: _profile,
                    accent: accent,
                    brandColor: leetCodeAmber,
                  ),
                ),
                const SizedBox(width: 24),
                // Right Side: Metrics Grid & Submissions Terminal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AdvancedLeetCodeMetricsGrid(profile: _profile, accent: accent),
                      const SizedBox(height: 24),
                      _AdvancedSubmissionsTerminal(
                        submissions: _submissions,
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
                _AdvancedLeetCodeProfileCard(
                  profile: _profile,
                  accent: accent,
                  brandColor: leetCodeAmber,
                ),
                const SizedBox(height: 24),
                _AdvancedLeetCodeMetricsGrid(profile: _profile, accent: accent),
                const SizedBox(height: 24),
                _AdvancedSubmissionsTerminal(
                  submissions: _submissions,
                  accent: accent,
                ),
              ],
            ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Advanced LeetCode Profile & Radial Progress Card
// ---------------------------------------------------------------------------
class _AdvancedLeetCodeProfileCard extends StatelessWidget {
  const _AdvancedLeetCodeProfileCard({
    required this.profile,
    required this.accent,
    required this.brandColor,
  });

  final Map<String, dynamic> profile;
  final Color accent;
  final Color brandColor;

  static const Color easyGreen = Color(0xFF00B8A3);
  static const Color mediumYellow = Color(0xFFFFC01E);
  static const Color hardRed = Color(0xFFFF375F);

  @override
  Widget build(BuildContext context) {
    final username = (profile['username'] as String?) ?? 'abhiii_sek';
    final name = (profile['realName'] as String?) ?? 'Abhishek Kumar Pal';
    final avatarUrl = (profile['avatar_url'] as String?) ?? 'https://assets.leetcode.com/users/abhiii_sek/avatar_1741775448.png';
    final totalSolved = (profile['totalSolved'] as int?) ?? 580;
    final totalQuestions = (profile['totalQuestions'] as int?) ?? 3999;
    final easySolved = (profile['easySolved'] as int?) ?? 261;
    final easyTotal = (profile['totalEasy'] as int?) ?? 956;
    final mediumSolved = (profile['mediumSolved'] as int?) ?? 278;
    final mediumTotal = (profile['totalMedium'] as int?) ?? 2088;
    final hardSolved = (profile['hardSolved'] as int?) ?? 41;
    final hardTotal = (profile['totalHard'] as int?) ?? 955;
    final profileUrl = 'https://leetcode.com/u/$username/';

    return BorderLightCard(
      glowColor: brandColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name & Handle
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: brandColor.withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: brandColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black,
                      child: Icon(Icons.terminal_rounded, color: brandColor, size: 28),
                    ),
                  ),
                ),
              ),
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
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(profileUrl), mode: LaunchMode.externalApplication),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          '@$username',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: brandColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Radial Problem Progress Ring Centerpiece
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _RadialProblemDialPainter(
                  easySolved: easySolved,
                  easyTotal: easyTotal,
                  mediumSolved: mediumSolved,
                  mediumTotal: mediumTotal,
                  hardSolved: hardSolved,
                  hardTotal: hardTotal,
                  totalSolved: totalSolved,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedCounter(
                        endValue: totalSolved,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBright,
                        ),
                      ),
                      Text(
                        '/ $totalQuestions',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: easyGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'SOLVED',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: easyGreen,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Tiers Progress Meter Bars
          _DifficultyTierBar(
            label: 'Easy',
            solved: easySolved,
            total: easyTotal,
            color: easyGreen,
          ),
          const SizedBox(height: 12),
          _DifficultyTierBar(
            label: 'Medium',
            solved: mediumSolved,
            total: mediumTotal,
            color: mediumYellow,
          ),
          const SizedBox(height: 12),
          _DifficultyTierBar(
            label: 'Hard',
            solved: hardSolved,
            total: hardTotal,
            color: hardRed,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: _ViewProfileButton(
              url: profileUrl,
              accent: brandColor,
              label: 'View Official LeetCode Profile',
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialProblemDialPainter extends CustomPainter {
  _RadialProblemDialPainter({
    required this.easySolved,
    required this.easyTotal,
    required this.mediumSolved,
    required this.mediumTotal,
    required this.hardSolved,
    required this.hardTotal,
    required this.totalSolved,
  });

  final int easySolved;
  final int easyTotal;
  final int mediumSolved;
  final int mediumTotal;
  final int hardSolved;
  final int hardTotal;
  final int totalSolved;

  static const Color easyGreen = Color(0xFF00B8A3);
  static const Color mediumYellow = Color(0xFFFFC01E);
  static const Color hardRed = Color(0xFFFF375F);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final total = (easySolved + mediumSolved + hardSolved).clamp(1, 9999);
    final easyAngle = (easySolved / total) * 2 * math.pi;
    final mediumAngle = (mediumSolved / total) * 2 * math.pi;
    final hardAngle = (hardSolved / total) * 2 * math.pi;

    const startAngle = -math.pi / 2;

    final easyPaint = Paint()
      ..color = easyGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      easyAngle,
      false,
      easyPaint,
    );

    final mediumPaint = Paint()
      ..color = mediumYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + easyAngle,
      mediumAngle,
      false,
      mediumPaint,
    );

    final hardPaint = Paint()
      ..color = hardRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + easyAngle + mediumAngle,
      hardAngle,
      false,
      hardPaint,
    );
  }

  @override
  bool shouldRepaint(_RadialProblemDialPainter old) =>
      easySolved != old.easySolved ||
      mediumSolved != old.mediumSolved ||
      hardSolved != old.hardSolved;
}

class _DifficultyTierBar extends StatelessWidget {
  const _DifficultyTierBar({
    required this.label,
    required this.solved,
    required this.total,
    required this.color,
  });

  final String label;
  final int solved;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (solved / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              Text(
                '$solved / $total',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedLeetCodeMetricsGrid extends StatelessWidget {
  const _AdvancedLeetCodeMetricsGrid({
    required this.profile,
    required this.accent,
  });

  final Map<String, dynamic> profile;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ranking = (profile['ranking'] as int?) ?? 145714;
    final contestRating = ((profile['contestRating'] as num?) ?? 1620.0).toDouble();
    final topPercentage = ((profile['acceptanceRate'] as num?) ?? 21.44).toDouble();
    final attendedContests = (profile['attendedContests'] as int?) ?? 22;
    final rep = (profile['reputation'] as int?) ?? 47;

    return BorderLightCard(
      glowColor: const Color(0xFFFFA116),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, size: 20, color: const Color(0xFFFFA116)),
              const SizedBox(width: 8),
              Text(
                'Competitive Rating & Performance Metrics',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 2 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isMobile ? 1.4 : 1.3,
                children: [
                  _MetricCardTile(
                    label: 'Contest Rating',
                    value: contestRating.toStringAsFixed(0),
                    subtitle: '$attendedContests Contests',
                    icon: Icons.speed_rounded,
                    color: const Color(0xFFFFA116),
                  ),
                  _MetricCardTile(
                    label: 'Global Rank',
                    value: '#${ranking.toString()}',
                    subtitle: 'Top Tier',
                    icon: Icons.emoji_events_outlined,
                    color: const Color(0xFFFFC01E),
                  ),
                  _MetricCardTile(
                    label: 'Top Percent',
                    value: '${topPercentage.toStringAsFixed(2)}%',
                    subtitle: 'Global Percentile',
                    icon: Icons.stars_rounded,
                    color: const Color(0xFF00B8A3),
                  ),
                  _MetricCardTile(
                    label: 'Reputation',
                    value: rep.toString(),
                    subtitle: '6 Badges Earned',
                    icon: Icons.military_tech_outlined,
                    color: const Color(0xFFFF375F),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricCardTile extends StatelessWidget {
  const _MetricCardTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textBright,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedSubmissionsTerminal extends StatelessWidget {
  const _AdvancedSubmissionsTerminal({
    required this.submissions,
    required this.accent,
  });

  final List<Map<String, dynamic>> submissions;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return BorderLightCard(
      glowColor: const Color(0xFFFFA116),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 18, color: const Color(0xFF00B8A3)),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Accepted Submissions (Live AC)',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBright,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B8A3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00B8A3).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00B8A3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VERIFIED AC',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00B8A3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final list = submissions.take(6).toList();
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 1 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 10,
                childAspectRatio: isMobile ? 3.6 : 3.4,
                children: list.map((sub) => _SubmissionGridCard(submission: sub, accent: accent)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SubmissionGridCard extends StatefulWidget {
  const _SubmissionGridCard({required this.submission, required this.accent});
  final Map<String, dynamic> submission;
  final Color accent;

  @override
  State<_SubmissionGridCard> createState() => _SubmissionGridCardState();
}

class _SubmissionGridCardState extends State<_SubmissionGridCard> {
  bool _hovered = false;

  Color _difficultyColor(String diff) => switch (diff.toLowerCase()) {
        'easy' => const Color(0xFF00B8A3),
        'hard' => const Color(0xFFFF375F),
        _ => const Color(0xFFFFC01E),
      };

  @override
  Widget build(BuildContext context) {
    final title = (widget.submission['title'] as String?) ?? 'Problem';
    final titleSlug = (widget.submission['titleSlug'] as String?) ?? '';
    final diff = (widget.submission['difficulty'] as String?) ?? 'Medium';
    final lang = (widget.submission['lang'] as String?) ?? 'java';
    final topic = (widget.submission['topic'] as String?) ?? 'Algorithms';
    final problemUrl = 'https://leetcode.com/problems/$titleSlug/';
    final diffColor = _difficultyColor(diff);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (titleSlug.isNotEmpty) {
            launchUrl(Uri.parse(problemUrl), mode: LaunchMode.externalApplication);
          }
        },
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFFFA116).withValues(alpha: 0.08)
                : AppColors.backgroundLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFFFFA116).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFA116).withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: Color(0xFF00B8A3),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          diff,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: diffColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: _hovered ? const Color(0xFFFFA116) : AppColors.textSecondary,
                  ),
                ],
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _hovered ? AppColors.textBright : AppColors.textBright,
                ),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      topic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA116).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      lang,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: const Color(0xFFFFA116),
                        fontWeight: FontWeight.bold,
                      ),
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

class _ViewProfileButton extends StatefulWidget {
  const _ViewProfileButton({
    required this.url,
    required this.accent,
    required this.label,
  });

  final String url;
  final Color accent;
  final String label;

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? widget.accent.withValues(alpha: 0.15) : Colors.transparent,
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
                    widget.label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _hovered ? AppColors.textBright : widget.accent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: _hovered ? AppColors.textBright : widget.accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
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
