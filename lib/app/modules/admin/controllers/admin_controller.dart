import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/api_constants.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';

class AdminController extends GetxController {
  // Login Controllers
  final emailLoginController = TextEditingController();
  final passwordLoginController = TextEditingController();

  // Personal Info Form Controllers
  final nameController = TextEditingController();
  final titleController = TextEditingController();
  final taglineController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final locationController = TextEditingController();
  final bioController = TextEditingController();
  final linkedInController = TextEditingController();
  final resumeController = TextEditingController();
  final githubController = TextEditingController();
  final leetcodeController = TextEditingController();
  final instagramController = TextEditingController();
  
  // Stats
  final expController = TextEditingController();
  final projectsController = TextEditingController();
  final techController = TextEditingController();

  // Auth State
  final isLoggedIn = false.obs;
  final jwtToken = ''.obs;
  final isLoading = false.obs;

  // Personal Info ID
  final personalId = ''.obs;

  // CRUD Lists
  final experiences = <Map<String, dynamic>>[].obs;
  final projects = <Map<String, dynamic>>[].obs;
  final skills = <Map<String, dynamic>>[].obs;
  final testimonials = <Map<String, dynamic>>[].obs;
  final educations = <Map<String, dynamic>>[].obs;
  final analytics = <Map<String, dynamic>>[].obs;

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (jwtToken.value.isNotEmpty) 'Authorization': 'Bearer ${jwtToken.value}',
  };

  @override
  void onInit() {
    super.onInit();
    _checkSavedAuth();
  }

  @override
  void onClose() {
    emailLoginController.dispose();
    passwordLoginController.dispose();
    nameController.dispose();
    titleController.dispose();
    taglineController.dispose();
    phoneController.dispose();
    emailController.dispose();
    locationController.dispose();
    bioController.dispose();
    linkedInController.dispose();
    resumeController.dispose();
    githubController.dispose();
    leetcodeController.dispose();
    instagramController.dispose();
    expController.dispose();
    projectsController.dispose();
    techController.dispose();
    super.onClose();
  }

  void _checkSavedAuth() {
    try {
      if (Get.isRegistered<ILocalStorageProvider>()) {
        final storage = Get.find<ILocalStorageProvider>();
        if (storage.isInitialized) {
          final savedToken = storage.getString('admin_jwt_token');
          if (savedToken != null && savedToken.isNotEmpty) {
            jwtToken.value = savedToken;
            isLoggedIn.value = true;
            loadDashboardData();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed checking saved auth: $e');
    }
    // Fallback to loading data from public view if not logged in
    _loadInitialDataFromLocal();
  }

  void _loadInitialDataFromLocal() {
    final lang = Get.find<LanguageController>();
    final info = lang.cvData['personal_info'] ?? {};

    nameController.text = info['name']?.toString() ?? '';
    titleController.text = info['title']?.toString() ?? '';
    taglineController.text = info['tagline']?.toString() ?? '';
    phoneController.text = info['phone']?.toString() ?? '';
    emailController.text = info['email']?.toString() ?? '';
    locationController.text = info['location']?.toString() ?? '';
    bioController.text = info['bio']?.toString() ?? '';
    linkedInController.text = info['linkedInUsername']?.toString() ?? '';
    resumeController.text = info['resumeUrl']?.toString() ?? '';
    githubController.text = info['githubUsername']?.toString() ?? '';
    leetcodeController.text = info['leetcodeUsername']?.toString() ?? '';
    instagramController.text = info['instagramUsername']?.toString() ?? '';

    final stats = info['stats'] ?? {};
    expController.text = stats['years_experience']?.toString() ?? '';
    projectsController.text = stats['projects_completed']?.toString() ?? '';
    techController.text = stats['technologies']?.toString() ?? '';
  }

  Future<void> login() async {
    if (emailLoginController.text.trim().isEmpty || passwordLoginController.text.isEmpty) {
      _showError('Validation Error', 'Email and password cannot be empty.');
      return;
    }

    isLoading.value = true;
    try {
      final payload = {
        'email': emailLoginController.text.trim(),
        'password': passwordLoginController.text,
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          jwtToken.value = token;
          isLoggedIn.value = true;

          // Save token to local storage
          if (Get.isRegistered<ILocalStorageProvider>()) {
            final storage = Get.find<ILocalStorageProvider>();
            await storage.setString('admin_jwt_token', token);
          }

          emailLoginController.clear();
          passwordLoginController.clear();

          _showSuccess('Login Success', 'Welcome back, Admin.');
          loadDashboardData();
        } else {
          _showError('Login Error', 'Failed to retrieve auth token.');
        }
      } else {
        _showError('Login Failed', 'Invalid email or password.');
      }
    } catch (e) {
      _showError('Connection Error', 'Failed to connect to authentication server: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    isLoggedIn.value = false;
    jwtToken.value = '';
    
    if (Get.isRegistered<ILocalStorageProvider>()) {
      final storage = Get.find<ILocalStorageProvider>();
      storage.remove('admin_jwt_token');
    }
    
    _loadInitialDataFromLocal();
    _showSuccess('Logged Out', 'You have been logged out successfully.');
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        loadPersonalInfo(),
        loadExperiences(),
        loadProjects(),
        loadSkills(),
        loadTestimonials(),
        loadEducations(),
        loadAnalytics(),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // CRUD - Personal Info
  // =========================================================================

  Future<void> loadPersonalInfo() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/personal-info'),
        headers: authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        if (list.isNotEmpty) {
          final info = list.first;
          personalId.value = info['personalId']?.toString() ?? '';
          nameController.text = info['name']?.toString() ?? '';
          titleController.text = info['title']?.toString() ?? '';
          taglineController.text = info['tagline']?.toString() ?? '';
          phoneController.text = info['phone']?.toString() ?? '';
          emailController.text = info['email']?.toString() ?? '';
          locationController.text = info['location']?.toString() ?? '';
          bioController.text = info['bio']?.toString() ?? '';
          linkedInController.text = info['linkedInUsername']?.toString() ?? '';
          resumeController.text = info['resumeUrl']?.toString() ?? '';
          githubController.text = info['githubUsername']?.toString() ?? '';
          leetcodeController.text = info['leetcodeUsername']?.toString() ?? '';
          instagramController.text = info['instagramUsername']?.toString() ?? '';

          expController.text = info['yearsExperience']?.toString() ?? '';
          projectsController.text = info['projectsCompleted']?.toString() ?? '';
          techController.text = info['technologies']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('Failed to load personal info: $e');
    }
  }

  Future<void> savePersonalInfo() async {
    // Phone validation (exactly 10 digits)
    final phone = phoneController.text.trim();
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showError('Validation Error', 'Phone number must be exactly 10 digits.');
      return;
    }

    isLoading.value = true;
    try {
      final payload = {
        'name': nameController.text.trim(),
        'title': titleController.text.trim(),
        'tagline': taglineController.text.trim(),
        'phone': phone,
        'email': emailController.text.trim(),
        'location': locationController.text.trim(),
        'bio': bioController.text.trim(),
        'linkedInUsername': linkedInController.text.trim().isEmpty ? 'admin' : linkedInController.text.trim(),
        'resumeUrl': resumeController.text.trim(),
        'githubUsername': githubController.text.trim(),
        'leetcodeUsername': leetcodeController.text.trim(),
        'instagramUsername': instagramController.text.trim(),
        'yearsExperience': int.tryParse(expController.text) ?? 0,
        'projectsCompleted': int.tryParse(projectsController.text) ?? 0,
        'technologies': int.tryParse(techController.text) ?? 0,
      };

      final bool isUpdate = personalId.value.isNotEmpty;
      final uri = isUpdate 
          ? Uri.parse('${ApiConstants.baseUrl}/api/admin/personal-info/${personalId.value}')
          : Uri.parse('${ApiConstants.baseUrl}/api/admin/personal-info');

      final response = isUpdate 
          ? await http.put(uri, headers: authHeaders, body: jsonEncode(payload))
          : await http.post(uri, headers: authHeaders, body: jsonEncode(payload));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Success', 'Personal information saved.');
        await loadPersonalInfo();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Server Error', 'Failed to save: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showError('Connection Error', 'Failed to save personal info: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // CRUD - Experiences
  // =========================================================================

  Future<void> loadExperiences() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/experiences'),
        headers: authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        experiences.value = list.cast<Map<String, dynamic>>().reversed.toList();
      }
    } catch (e) {
      debugPrint('Failed to load experiences: $e');
    }
  }

  Future<void> saveExperience(String? id, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final response = id != null
          ? await http.put(Uri.parse('${ApiConstants.baseUrl}/api/admin/experiences/$id'), headers: authHeaders, body: jsonEncode(data))
          : await http.post(Uri.parse('${ApiConstants.baseUrl}/api/admin/experiences'), headers: authHeaders, body: jsonEncode(data));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Success', 'Experience saved.');
        await loadExperiences();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Error', 'Failed to save experience: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error', 'Failed to save experience: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteExperience(String id) async {
    isLoading.value = true;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/experiences/$id'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        _showSuccess('Success', 'Experience deleted.');
        await loadExperiences();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Error', 'Failed to delete experience: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error', 'Failed to delete experience: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // CRUD - Projects
  // =========================================================================

  Future<void> loadProjects() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/projects'),
        headers: authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        projects.value = list.cast<Map<String, dynamic>>().reversed.toList();
      }
    } catch (e) {
      debugPrint('Failed to load projects: $e');
    }
  }

  Future<void> saveProject(String? id, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final response = id != null
          ? await http.put(Uri.parse('${ApiConstants.baseUrl}/api/admin/projects/$id'), headers: authHeaders, body: jsonEncode(data))
          : await http.post(Uri.parse('${ApiConstants.baseUrl}/api/admin/projects'), headers: authHeaders, body: jsonEncode(data));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Success', 'Project saved.');
        await loadProjects();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Error', 'Failed to save project: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showError('Error', 'Failed to save project: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProject(String id) async {
    isLoading.value = true;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/projects/$id'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        _showSuccess('Success', 'Project deleted.');
        await loadProjects();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Error', 'Failed to delete project: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error', 'Failed to delete project: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // CRUD - Skills
  // =========================================================================

  Future<void> loadSkills() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/skills'),
        headers: authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        skills.value = list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Failed to load skills: $e');
    }
  }

  Future<void> saveSkill(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/skills'),
        headers: authHeaders,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Success', 'Skill saved.');
        await loadSkills();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Error', 'Failed to save skill: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error', 'Failed to save skill: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSkill(String id) async {
    isLoading.value = true;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/skills/$id'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        _showSuccess('Success', 'Skill deleted.');
        await loadSkills();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Error', 'Failed to delete skill: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error', 'Failed to delete skill: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // CRUD - Testimonials
  // =========================================================================

  Future<void> loadTestimonials() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/testimonials'),
        headers: authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        testimonials.value = list.cast<Map<String, dynamic>>().reversed.toList();
      }
    } catch (e) {
      debugPrint('Failed to load testimonials: $e');
    }
  }

  Future<void> saveTestimonial(String? id, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final response = id != null
          ? await http.put(Uri.parse('${ApiConstants.baseUrl}/api/admin/testimonials/$id'), headers: authHeaders, body: jsonEncode(data))
          : await http.post(Uri.parse('${ApiConstants.baseUrl}/api/admin/testimonials'), headers: authHeaders, body: jsonEncode(data));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Success', 'Testimonial saved.');
        await loadTestimonials();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Error', 'Failed to save testimonial: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error', 'Failed to save testimonial: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTestimonial(String id) async {
    isLoading.value = true;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/testimonials/$id'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        _showSuccess('Success', 'Testimonial deleted.');
        await loadTestimonials();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Error', 'Failed to delete testimonial: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error', 'Failed to delete testimonial: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // CRUD - Educations
  // =========================================================================

  Future<void> loadEducations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/educations'),
        headers: authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        final casted = list.cast<Map<String, dynamic>>();
        casted.sort((a, b) {
          final toA = int.tryParse(a['to']?.toString() ?? '') ?? 0;
          final toB = int.tryParse(b['to']?.toString() ?? '') ?? 0;
          return toB.compareTo(toA);
        });
        educations.value = casted;
      }
    } catch (e) {
      debugPrint('Failed to load educations: $e');
    }
  }

  Future<void> saveEducation(String? id, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final response = id != null
          ? await http.put(Uri.parse('${ApiConstants.baseUrl}/api/admin/educations/$id'), headers: authHeaders, body: jsonEncode(data))
          : await http.post(Uri.parse('${ApiConstants.baseUrl}/api/admin/educations'), headers: authHeaders, body: jsonEncode(data));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Success', 'Education details saved.');
        await loadEducations();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Error', 'Failed to save education: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showError('Error', 'Failed to save education: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEducation(String id) async {
    isLoading.value = true;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/educations/$id'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        _showSuccess('Success', 'Education details deleted.');
        await loadEducations();
        await Get.find<LanguageController>().loadPortfolioData();
      } else {
        _showError('Error', 'Failed to delete education: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error', 'Failed to delete education: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // Visitor Analytics
  // =========================================================================

  Future<void> loadAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/analytics'),
        headers: authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        analytics.value = list.cast<Map<String, dynamic>>().reversed.toList();
      }
    } catch (e) {
      debugPrint('Failed to load analytics: $e');
    }
  }

  // =========================================================================
  // Feedback helpers
  // =========================================================================

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      maxWidth: 400,
      margin: const EdgeInsets.all(20),
    );
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      maxWidth: 400,
      margin: const EdgeInsets.all(20),
    );
  }
}
