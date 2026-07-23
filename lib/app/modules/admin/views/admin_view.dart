import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/modules/admin/controllers/admin_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_button.dart';
import 'package:flutter_web_portfolio/app/routes/app_pages.dart';

class AdminView extends GetView<AdminController> {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Color(0xFF0F1E36),
                    AppColors.backgroundDark,
                  ],
                ),
              ),
            ),
          ),

          // Main Body
          Obx(() {
            if (!controller.isLoggedIn.value) {
              return _buildLoginScreen(context);
            }
            return _buildDashboardScreen(context);
          }),
        ],
      ),
    );

  // =========================================================================
  // LOGIN SCREEN
  // =========================================================================
  Widget _buildLoginScreen(BuildContext context) => Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.heroAccent.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PORTFOLIO ADMIN',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBright,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Get.offAllNamed(Routes.home),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Please sign in with your administrator credentials to access database operations.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Inputs
              _buildTextField('Email Address', controller.emailLoginController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildTextField('Password', controller.passwordLoginController, obscureText: true),
              const SizedBox(height: 36),

              // Submit Button
              Obx(() => controller.isLoading.value
                  ? Center(child: CircularProgressIndicator(color: AppColors.heroAccent))
                  : Container(
                      width: double.infinity,
                      height: 50,
                      child: Center(
                        child: CinematicButton(
                          label: 'AUTHENTICATE',
                          onTap: controller.login,
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );

  // =========================================================================
  // DASHBOARD SCREEN
  // =========================================================================
  Widget _buildDashboardScreen(BuildContext context) => DefaultTabController(
      length: 7,
      child: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.heroAccent.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTROL CENTER',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBright,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome Admin',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.heroAccent,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Obx(() {
                        final themeController = Get.find<ThemeController>();
                        return IconButton(
                          tooltip: 'Toggle Theme',
                          icon: Icon(
                            themeController.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: AppColors.accent,
                          ),
                          onPressed: themeController.toggleTheme,
                        );
                      }),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'View Live Portfolio',
                        icon: Icon(Icons.open_in_new, color: AppColors.textSecondary),
                        onPressed: () => Get.offAllNamed(Routes.home),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Sign Out',
                        icon: Icon(Icons.logout, color: Colors.redAccent),
                        onPressed: controller.logout,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab bar selectors
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.heroAccent,
              labelColor: AppColors.textBright,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, letterSpacing: 1),
              unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'PERSONAL DETAILS'),
                Tab(text: 'EXPERIENCES'),
                Tab(text: 'PROJECTS'),
                Tab(text: 'SKILLS'),
                Tab(text: 'TESTIMONIALS'),
                Tab(text: 'EDUCATION'),
                Tab(text: 'VISITOR ANALYTICS'),
              ],
            ),

            // Main Tab Contents
            Expanded(
              child: Stack(
                children: [
                  TabBarView(
                    children: [
                      _buildPersonalInfoTab(context),
                      _buildExperiencesTab(context),
                      _buildProjectsTab(context),
                      _buildSkillsTab(context),
                      _buildTestimonialsTab(context),
                      _buildEducationsTab(context),
                      _buildAnalyticsTab(context),
                    ],
                  ),
                  Obx(() {
                    if (!controller.isLoading.value) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.55),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.heroAccent),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  // =========================================================================
  // TAB 1: PERSONAL INFO
  // =========================================================================
  Widget _buildPersonalInfoTab(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Profile Identity'),
              Row(
                children: [
                  Expanded(child: _buildTextField('Full Name', controller.nameController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Professional Title', controller.titleController)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Intro Tagline', controller.taglineController),
              const SizedBox(height: 16),
              _buildTextField('Bio (Markdown / Paragraph)', controller.bioController, maxLines: 4),
              const SizedBox(height: 32),

              _buildSectionHeader('Contact & Handles'),
              Row(
                children: [
                  Expanded(child: _buildTextField('Email Address', controller.emailController, keyboardType: TextInputType.emailAddress)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Phone Number', controller.phoneController, keyboardType: TextInputType.phone)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Location (City, Country)', controller.locationController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('LinkedIn Username', controller.linkedInController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('GitHub Username', controller.githubController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Leetcode Username', controller.leetcodeController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Instagram Username', controller.instagramController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Resume URL (Google Drive)', controller.resumeController)),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('Visual Stats'),
              Row(
                children: [
                  Expanded(child: _buildTextField('Years of Experience', controller.expController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Projects Completed', controller.projectsController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Technologies (Total count, e.g. 15)', controller.techController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 48),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CinematicButton(
                    label: 'SAVE PROFILE CHANGES',
                    onTap: controller.savePersonalInfo,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

  // =========================================================================
  // TAB 2: EXPERIENCES
  // =========================================================================
  Widget _buildExperiencesTab(BuildContext context) => _buildTabContainer(
      title: 'Work Experience',
      onAdd: () => _showExperienceDialog(context, null),
      child: ListView.separated(
        itemCount: controller.experiences.length,
        separatorBuilder: (c, i) => Divider(color: Colors.white.withValues(alpha: 0.05)),
        itemBuilder: (context, index) {
          final exp = controller.experiences[index];
          final String id = exp['experienceId']?.toString() ?? '';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              '${exp['position']} @ ${exp['company']}',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textBright, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${exp['startDate'] ?? exp['start_date'] ?? ''} — ${exp['endDate'] ?? exp['end_date'] ?? 'Present'}',
                  style: GoogleFonts.inter(color: AppColors.heroAccent, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  exp['description']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () => _showExperienceDialog(context, exp),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, 'Experience', () => controller.deleteExperience(id)),
                ),
              ],
            ),
          );
        },
      ),
    );

  // =========================================================================
  // TAB 3: PROJECTS
  // =========================================================================
  Widget _buildProjectsTab(BuildContext context) => _buildTabContainer(
      title: 'Projects Showcase',
      onAdd: () => _showProjectDialog(context, null),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 220,
        ),
        itemCount: controller.projects.length,
        itemBuilder: (context, index) {
          final proj = controller.projects[index];
          final String id = proj['projectId']?.toString() ?? '';
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? AppColors.backgroundLight.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Get.isDarkMode
                    ? AppColors.heroAccent.withValues(alpha: 0.1)
                    : AppColors.textSecondary.withValues(alpha: 0.15),
              ),
              boxShadow: Get.isDarkMode ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proj['title']?.toString() ?? '',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.textBright, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  proj['category']?.toString() ?? '',
                  style: GoogleFonts.inter(color: AppColors.heroAccent, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    proj['description']?.toString() ?? '',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                      onPressed: () => _showProjectDialog(context, proj),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      onPressed: () => _confirmDelete(context, 'Project', () => controller.deleteProject(id)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

  // =========================================================================
  // TAB 4: SKILLS
  // =========================================================================
  Widget _buildSkillsTab(BuildContext context) {
    final catController = TextEditingController();
    final nameController = TextEditingController();

    return _buildTabContainer(
      title: 'Skills Matrix',
      onAdd: () {
        Get.dialog(
          AlertDialog(
            backgroundColor: const Color(0xFF0D0E15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.accent.withOpacity(0.15), width: 1.5),
            ),
            title: Text('Add Skill', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Category (e.g. Frontend)', catController, isRequired: true, forceDark: true),
                const SizedBox(height: 16),
                _buildTextField('Skill Name (e.g. Flutter)', nameController, isRequired: true, forceDark: true),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8)))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.heroAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (catController.text.trim().isNotEmpty && nameController.text.trim().isNotEmpty) {
                    controller.saveSkill({
                      'category': catController.text.trim(),
                      'name': nameController.text.trim(),
                    });
                    Get.back();
                  } else {
                    Get.snackbar(
                      'Validation Error',
                      'Please fill in all required fields marked with *',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.withOpacity(0.1),
                      colorText: Colors.white,
                      borderColor: Colors.red.withOpacity(0.5),
                      borderWidth: 1,
                    );
                  }
                },
                child: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      child: ListView.builder(
        itemCount: controller.skills.length,
        itemBuilder: (context, index) {
          final skill = controller.skills[index];
          final String id = skill['skillId']?.toString() ?? '';
          return ListTile(
            title: Text(skill['name']?.toString() ?? '', style: TextStyle(color: AppColors.textBright)),
            subtitle: Text(skill['category']?.toString() ?? '', style: TextStyle(color: AppColors.heroAccent)),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, 'Skill', () => controller.deleteSkill(id)),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // TAB 5: TESTIMONIALS
  // =========================================================================
  Widget _buildTestimonialsTab(BuildContext context) => _buildTabContainer(
      title: 'Client Recommendations',
      onAdd: () => _showTestimonialDialog(context, null),
      child: ListView.separated(
        itemCount: controller.testimonials.length,
        separatorBuilder: (c, i) => Divider(color: Colors.white.withValues(alpha: 0.05)),
        itemBuilder: (context, index) {
          final test = controller.testimonials[index];
          final String id = test['testimonialId']?.toString() ?? '';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              test['name']?.toString() ?? '',
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${test['position']} at ${test['company']}',
                  style: GoogleFonts.inter(color: AppColors.heroAccent, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '"${test['quote']}"',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () => _showTestimonialDialog(context, test),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, 'Testimonial', () => controller.deleteTestimonial(id)),
                ),
              ],
            ),
          );
        },
      ),
    );

  // =========================================================================
  // TAB 6: EDUCATIONS
  // =========================================================================
  Widget _buildEducationsTab(BuildContext context) => _buildTabContainer(
      title: 'Educational Credentials',
      onAdd: () => _showEducationDialog(context, null),
      child: ListView.separated(
        itemCount: controller.educations.length,
        separatorBuilder: (c, i) => Divider(color: Colors.white.withValues(alpha: 0.05)),
        itemBuilder: (context, index) {
          final edu = controller.educations[index];
          final String id = edu['educationId']?.toString() ?? '';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              edu['school']?.toString() ?? '',
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${edu['degree'] ?? 'Degree'} • ${edu['year'] ?? edu['period'] ?? ''}',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () => _showEducationDialog(context, edu),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, 'Education entry', () => controller.deleteEducation(id)),
                ),
              ],
            ),
          );
        },
      ),
    );

  // =========================================================================
  // TAB 7: VISITOR ANALYTICS
  // =========================================================================
  Widget _buildAnalyticsTab(BuildContext context) {
    final list = controller.analytics;
    final totalVisits = list.length;
    final uniqueVisits = list.map((a) {
      final vId = a['visitorId']?.toString();
      if (vId != null && vId.isNotEmpty) {
        return vId;
      }
      return a['ip']?.toString() ?? '';
    }).where((id) => id.isNotEmpty).toSet().length;
    final repeatingVisits = totalVisits > uniqueVisits ? totalVisits - uniqueVisits : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Metrics Cards
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Visits', '$totalVisits', Icons.people_outline, AppColors.heroAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Unique Visitors', '$uniqueVisits', Icons.person_outline, AppColors.expAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Repeating Visits', '$repeatingVisits', Icons.cached, AppColors.projAccent)),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            'VISIT METRICS LOG',
            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBright, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Get.isDarkMode ? AppColors.background.withValues(alpha: 0.5) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Get.isDarkMode 
                    ? AppColors.heroAccent.withValues(alpha: 0.1) 
                    : AppColors.textSecondary.withValues(alpha: 0.15),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: GoogleFonts.spaceGrotesk(color: AppColors.heroAccent, fontWeight: FontWeight.bold),
                dataTextStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                columns: const [
                  DataColumn(label: Text('IP Address')),
                  DataColumn(label: Text('City')),
                  DataColumn(label: Text('Country')),
                  DataColumn(label: Text('Device')),
                  DataColumn(label: Text('Frequency')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Timestamp')),
                ],
                rows: list.map((a) => DataRow(cells: [
                    DataCell(Text(a['ip']?.toString() ?? 'Unknown')),
                    DataCell(Text(a['city']?.toString() ?? 'Unknown')),
                    DataCell(Text(a['country']?.toString() ?? 'Unknown')),
                    DataCell(Text(a['deviceType']?.toString() ?? 'Unknown')),
                    DataCell(Text(a['frequency']?.toString() ?? '1')),
                    DataCell(Text(
                      a['repeating'] == true ? 'Returning' : 'New',
                      style: TextStyle(
                        color: a['repeating'] == true ? AppColors.expAccent : AppColors.projAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
                    DataCell(Text(a['timestamp']?.toString().split('.').first.replaceAll('T', ' ') ?? '')),
                  ])).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color col) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? AppColors.background.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withValues(alpha: 0.15), width: 1),
        boxShadow: Get.isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Text(val, style: GoogleFonts.spaceGrotesk(color: AppColors.textBright, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, color: col, size: 36),
        ],
      ),
    );

  // =========================================================================
  // DIALOGS & POPUPS
  // =========================================================================
  void _showExperienceDialog(BuildContext context, Map<String, dynamic>? exp) {
    final titleC = TextEditingController(text: exp?['title']?.toString() ?? '');
    final compC = TextEditingController(text: exp?['company']?.toString() ?? '');
    final posC = TextEditingController(text: exp?['position']?.toString() ?? '');
    final startC = TextEditingController(text: exp?['start_date']?.toString() ?? '');
    final endC = TextEditingController(text: exp?['end_date']?.toString() ?? '');
    final descC = TextEditingController(text: exp?['description']?.toString() ?? '');
    final techC = TextEditingController(text: (exp?['technologies'] as List?)?.join(', ') ?? '');

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF0D0E15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.accent.withOpacity(0.15), width: 1.5),
        ),
        scrollable: true,
        title: Text(exp == null ? 'Add Experience' : 'Edit Experience', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Position (e.g. Lead Engineer)', posC, isRequired: true, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Company Name', compC, isRequired: true, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Role Category / Title', titleC, isRequired: true, forceDark: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField('Start Date (e.g. Jan 2022)', startC, isRequired: true, forceDark: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('End Date (Present if current)', endC, forceDark: true)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField('Technologies (Comma-separated)', techC, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Job Description / Responsibilities', descC, maxLines: 4, forceDark: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.heroAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (titleC.text.trim().isEmpty || compC.text.trim().isEmpty || posC.text.trim().isEmpty || startC.text.trim().isEmpty) {
                Get.snackbar(
                  'Validation Error',
                  'Please fill in all required fields marked with *',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.white,
                  borderColor: Colors.red.withOpacity(0.5),
                  borderWidth: 1,
                );
                return;
              }
              final String? id = exp?['experienceId']?.toString();
              final techs = techC.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              controller.saveExperience(id, {
                'title': titleC.text.trim(),
                'company': compC.text.trim(),
                'position': posC.text.trim(),
                'startDate': startC.text.trim(),
                'endDate': endC.text.trim().isEmpty ? 'Present' : endC.text.trim(),
                'description': descC.text.trim(),
                'technologies': techs.isEmpty ? ['Flutter'] : techs,
                'period': '${startC.text} — ${endC.text.isEmpty ? 'Present' : endC.text}'
              });
              Get.back();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProjectDialog(BuildContext context, Map<String, dynamic>? proj) {
    final titleC = TextEditingController(text: proj?['title']?.toString() ?? '');
    final catC = TextEditingController(text: proj?['category']?.toString() ?? '');
    final descC = TextEditingController(text: proj?['description']?.toString() ?? '');
    
    // Resolving URLs Map or String
    String url = '';
    String gp = '';
    String as = '';
    String web = '';
    final urlData = proj?['url'];
    if (urlData is Map) {
      gp = urlData['google_play']?.toString() ?? '';
      as = urlData['app_store']?.toString() ?? '';
      web = urlData['website']?.toString() ?? '';
    } else if (urlData is String) {
      url = urlData;
    }

    final urlC = TextEditingController(text: url);
    final gpC = TextEditingController(text: gp);
    final asC = TextEditingController(text: as);
    final webC = TextEditingController(text: web);

    final caseStudy = proj?['case_study'] as Map?;
    final probC = TextEditingController(text: caseStudy?['problem']?.toString() ?? '');
    final solC = TextEditingController(text: caseStudy?['solution']?.toString() ?? '');
    final resC = TextEditingController(text: caseStudy?['result']?.toString() ?? '');
    final imgC = TextEditingController(text: proj?['image']?.toString() ?? 'assets/images/project_default.png');

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF0D0E15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.accent.withOpacity(0.15), width: 1.5),
        ),
        scrollable: true,
        title: Text(proj == null ? 'Add Project' : 'Edit Project', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Project Title', titleC, isRequired: true, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Category (e.g. Flutter Web)', catC, isRequired: true, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Image Assets Path', imgC, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Primary Project URL', urlC, forceDark: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField('Web Live Link', webC, forceDark: true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField('Google Play Store Link', gpC, forceDark: true)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField('Apple App Store Link', asC, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Problem Statement', probC, maxLines: 2, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Solution Details', solC, maxLines: 2, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Outcome / Results', resC, maxLines: 2, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Brief Description', descC, maxLines: 3, isRequired: true, forceDark: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.heroAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (titleC.text.trim().isEmpty || catC.text.trim().isEmpty || descC.text.trim().isEmpty) {
                Get.snackbar(
                  'Validation Error',
                  'Please fill in all required fields marked with *',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.white,
                  borderColor: Colors.red.withOpacity(0.5),
                  borderWidth: 1,
                );
                return;
              }
              final String? id = proj?['projectId']?.toString();
              controller.saveProject(id, {
                'title': titleC.text.trim(),
                'description': descC.text.trim(),
                'category': catC.text.trim(),
                'url': urlC.text.trim().isEmpty ? null : urlC.text.trim(),
                'image': imgC.text.trim(),
                'googlePlayUrl': gpC.text.trim().isEmpty ? null : gpC.text.trim(),
                'appStoreUrl': asC.text.trim().isEmpty ? null : asC.text.trim(),
                'websiteUrl': webC.text.trim().isEmpty ? null : webC.text.trim(),
                'problem': probC.text.trim().isEmpty ? 'Generic Problem Statement' : probC.text.trim(),
                'solution': solC.text.trim().isEmpty ? 'Generic Solution Details' : solC.text.trim(),
                'result': resC.text.trim().isEmpty ? 'Generic Result Output' : resC.text.trim(),
              });
              Get.back();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTestimonialDialog(BuildContext context, Map<String, dynamic>? test) {
    final quoteC = TextEditingController(text: test?['quote']?.toString() ?? '');
    final nameC = TextEditingController(text: test?['name']?.toString() ?? '');
    final posC = TextEditingController(text: test?['position']?.toString() ?? '');
    final compC = TextEditingController(text: test?['company']?.toString() ?? '');

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF0D0E15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.accent.withOpacity(0.15), width: 1.5),
        ),
        scrollable: true,
        title: Text(test == null ? 'Add Testimonial' : 'Edit Testimonial', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Client Name', nameC, isRequired: true, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Professional Title (e.g. Product Manager)', posC, isRequired: true, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Company Name', compC, isRequired: true, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Client Quote', quoteC, maxLines: 4, isRequired: true, forceDark: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.heroAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (nameC.text.trim().isEmpty || posC.text.trim().isEmpty || compC.text.trim().isEmpty || quoteC.text.trim().isEmpty) {
                Get.snackbar(
                  'Validation Error',
                  'Please fill in all required fields marked with *',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.white,
                  borderColor: Colors.red.withOpacity(0.5),
                  borderWidth: 1,
                );
                return;
              }
              final String? id = test?['testimonialId']?.toString();
              controller.saveTestimonial(id, {
                'name': nameC.text.trim(),
                'position': posC.text.trim(),
                'company': compC.text.trim(),
                'quote': quoteC.text.trim(),
              });
              Get.back();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEducationDialog(BuildContext context, Map<String, dynamic>? edu) {
    final schoolC = TextEditingController(text: edu?['school']?.toString() ?? '');
    final degreeC = TextEditingController(text: edu?['degree']?.toString() ?? '');
    final fromC = TextEditingController(text: edu?['from']?.toString() ?? '2018');
    final toC = TextEditingController(text: edu?['to']?.toString() ?? '2022');
    final pctC = TextEditingController(text: edu?['percentage']?.toString() ?? '95.0');
    final periodC = TextEditingController(text: edu?['period']?.toString() ?? '');

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF0D0E15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.accent.withOpacity(0.15), width: 1.5),
        ),
        scrollable: true,
        title: Text(edu == null ? 'Add Education' : 'Edit Education', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('School / Institution Name', schoolC, isRequired: true, forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Degree Details', degreeC, isRequired: true, forceDark: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField('Start Year', fromC, keyboardType: TextInputType.number, forceDark: true)),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField('End Year', toC, keyboardType: TextInputType.number, forceDark: true)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField('Grade Percentage (0-100)', pctC, keyboardType: const TextInputType.numberWithOptions(decimal: true), forceDark: true),
            const SizedBox(height: 12),
            _buildTextField('Period display string (optional)', periodC, forceDark: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.heroAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (schoolC.text.trim().isEmpty || degreeC.text.trim().isEmpty) {
                Get.snackbar(
                  'Validation Error',
                  'Please fill in all required fields marked with *',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.white,
                  borderColor: Colors.red.withOpacity(0.5),
                  borderWidth: 1,
                );
                return;
              }
              final String? id = edu?['educationId']?.toString();
              controller.saveEducation(id, {
                'school': schoolC.text.trim(),
                'degree': degreeC.text.trim(),
                'from': int.tryParse(fromC.text) ?? 2018,
                'to': int.tryParse(toC.text) ?? 2022,
                'percentage': double.tryParse(pctC.text) ?? 95.0,
                'year': periodC.text.trim().isEmpty 
                    ? '${fromC.text} — ${toC.text}'
                    : periodC.text.trim()
              });
              Get.back();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String element, VoidCallback onConfirm) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF0D0E15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.20), width: 1.5),
        ),
        title: Text('Delete $element?', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete this $element from the database?', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              onConfirm();
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPERS
  // =========================================================================
  Widget _buildTabContainer({required String title, required Widget child, required VoidCallback onAdd}) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBright, letterSpacing: 1.5),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.heroAccent),
                icon: Icon(Icons.add, color: Colors.white, size: 18),
                label: Text('ADD NEW', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Get.isDarkMode ? AppColors.background.withValues(alpha: 0.5) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Get.isDarkMode
                      ? AppColors.heroAccent.withValues(alpha: 0.1)
                      : AppColors.textSecondary.withValues(alpha: 0.15),
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );

  Widget _buildSectionHeader(String title) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.heroAccent,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: AppColors.heroAccent.withValues(alpha: 0.15), height: 1),
        const SizedBox(height: 16),
      ],
    );

  Widget _buildTextField(
    String label,
    TextEditingController textController, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isRequired = false,
    bool forceDark = false,
  }) {
    final isDark = forceDark || Get.isDarkMode;
    final labelColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
    final textColor = isDark ? const Color(0xFFF8FAFC) : AppColors.textBright;
    final fieldBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.textSecondary.withValues(alpha: 0.25);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: textController,
          maxLines: maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: GoogleFonts.inter(color: textColor, fontSize: 14),
          cursorColor: AppColors.heroAccent,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.heroAccent, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: borderColor,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
