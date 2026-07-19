import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_portfolio/app/core/constants/api_constants.dart';
import 'package:kartal/kartal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/magnetic_button.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';

/// Contact Section — "The Finale"
/// White particles on deep black, shader reveal title, magnetic CTA button,
/// and a Formspree-powered contact form.
class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final data = languageController.cvData['personal_info'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final email = (data['email'] as String?) ?? 'hello@example.com';
    final screenWidth = context.sized.width;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 0,
      ),
      child: Stack(
        children: [
          // Giant watermark — derived from nav i18n
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() => Text(
                languageController.getText('nav.contact', defaultValue: 'Contact').toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: ResponsiveUtils.getValueForScreenType<double>(
                    context: context,
                    mobile: 48.0,
                    tablet: screenWidth * 0.14,
                    desktop: screenWidth * 0.18,
                  ),
                  fontWeight: FontWeight.w800,
                  color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black)
                      .withValues(alpha: 0.03),
                  letterSpacing: -2,
                ),
              )),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    // Title
                    ScrollFadeIn(
                      child: Obx(() {
                        final accent = Get.find<SceneDirector>().currentAccent.value;
                        return NumberedSectionHeading(
                          number: '06',
                          title: languageController.getText(
                            'contact_section.title',
                            defaultValue: 'Get In Touch',
                          ),
                          accent: accent,
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // Description
                    ScrollFadeIn(
                      delay: AppDurations.staggerMedium,
                      child: Text(
                        languageController.getText(
                          'contact_section.description',
                          defaultValue: 'I\'m always open to new challenges and '
                              'collaborations. Whether you have a project idea, '
                              'a question, or just want to connect — feel free '
                              'to reach out!',
                        ),
                        style: AppTypography.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Magnetic CTA button
                    ScrollFadeIn(
                      delay: AppDurations.normal,
                      child: _MagneticCTA(email: email),
                    ),
                    const SizedBox(height: 40),
                    // "or" divider
                    ScrollFadeIn(
                      delay: AppDurations.staggerLong,
                      child: Obx(() => Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              languageController.getText(
                                'contact_section.form.or_divider',
                                defaultValue: 'or send a message directly',
                              ),
                              style: AppTypography.caption,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      )),
                    ),
                    const SizedBox(height: 40),
                    // Contact Form
                    const ScrollFadeIn(
                      delay: AppDurations.staggerXLong,
                      child: _ContactForm(),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Magnetic CTA — cursor-attracting "Say Hello"
class _MagneticCTA extends StatelessWidget {
  const _MagneticCTA({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => Obx(() {
    final accent = Get.find<SceneDirector>().currentAccent.value;
    final label = Get.find<LanguageController>().getText(
      'translations.send_message',
      defaultValue: 'Say Hello',
    );
    return Semantics(
      button: true,
      label: label,
      child: MagneticButton(
        onTap: () async {
          final uri = Uri.parse('mailto:$email');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
          child: _HoverContainer(
          accent: accent,
          label: label,
        ),
      ),
    );
  });
}

class _HoverContainer extends StatefulWidget {
  const _HoverContainer({required this.accent, required this.label});
  final Color accent;
  final String label;

  @override
  State<_HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<_HoverContainer> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: AppDurations.buttonHover,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: _hovered
            ? widget.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hovered
              ? widget.accent
              : widget.accent.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: _hovered
            ? [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ]
            : [],
      ),
      child: Text(
        widget.label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: widget.accent,
          letterSpacing: 2,
        ),
      ),
    ),
  );
}

/// Formspree-powered contact form with cinematic styling.
class _ContactForm extends StatefulWidget {
  const _ContactForm();

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

enum _FormStatus { idle, sending, success, error }

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  _FormStatus _status = _FormStatus.idle;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Validates the form fields, gathers text controller values, and submits
  /// visitor contact details to the Spring Boot REST API.
  Future<void> _submit() async {
    // 1. Check if all form inputs (name, email, message) are valid
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 2. Transition form status to 'sending' to show a loader on the button
    setState(() => _status = _FormStatus.sending);

    try {
      // 3. Make HTTP POST request containing JSON body to the Spring backend endpoint.
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/public/contact'),
        headers: {
          'Content-Type': 'application/json', // Inform API that body contains JSON data
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'message': _messageController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15)); // Abort connection if it takes >15s

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _status = _FormStatus.success);
        
        // Clear all text entry controllers
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
        
        // Reset to idle status after a delayed window
        Future.delayed(AppDurations.formResetDelay, () {
          if (mounted) setState(() => _status = _FormStatus.idle);
        });
      } else {
        // If HTTP status is not 200, transition to error status
        setState(() => _status = _FormStatus.error);
        Future.delayed(AppDurations.formResetDelay, () {
          if (mounted) setState(() => _status = _FormStatus.idle);
        });
      }
    } catch (e) {
      // Catch socket timeouts, server offline issues, or DNS errors
      dev.log('Contact form API submission failed', name: 'ContactForm', error: e);
      if (!mounted) return;
      setState(() => _status = _FormStatus.error);
      Future.delayed(AppDurations.formResetDelay, () {
        if (mounted) setState(() => _status = _FormStatus.idle);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Get.find<LanguageController>();

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;

      return Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field
            _CinematicTextField(
              controller: _nameController,
              label: lang.getText(
                'contact_section.form.name_label',
                defaultValue: 'Name',
              ),
              accent: accent,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return lang.getText(
                    'contact_section.form.name_error',
                    defaultValue: 'Please enter your name',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Email field
            _CinematicTextField(
              controller: _emailController,
              label: lang.getText(
                'contact_section.form.email_label',
                defaultValue: 'Email',
              ),
              accent: accent,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return lang.getText(
                    'contact_section.form.email_error',
                    defaultValue: 'Please enter a valid email',
                  );
                }
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(value.trim())) {
                  return lang.getText(
                    'contact_section.form.email_error',
                    defaultValue: 'Please enter a valid email',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Message field
            _CinematicTextField(
              controller: _messageController,
              label: lang.getText(
                'contact_section.form.message_label',
                defaultValue: 'Message',
              ),
              accent: accent,
              maxLines: 5,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return lang.getText(
                    'contact_section.form.message_error',
                    defaultValue: 'Please enter your message',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            // Status message
            AnimatedSwitcher(
              duration: AppDurations.medium,
              child: switch (_status) {
                _FormStatus.success => Padding(
                  key: const ValueKey('success'),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: AppColors.expAccent, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          lang.getText(
                            'contact_section.form.success',
                            defaultValue:
                                'Your message has been sent successfully!',
                          ),
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.expAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                _FormStatus.error => Padding(
                  key: const ValueKey('error'),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppColors.projAccent, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          lang.getText(
                            'contact_section.form.error',
                            defaultValue:
                                'An error occurred. Please try again.',
                          ),
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.projAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                _ => const SizedBox.shrink(key: ValueKey('idle')),
              },
            ),
            // Submit button
            _SubmitButton(
              accent: accent,
              label: lang.getText(
                'contact_section.form.submit_button',
                defaultValue: 'Send Message',
              ),
              isSending: _status == _FormStatus.sending,
              onTap: _status == _FormStatus.sending ? null : _submit,
            ),
          ],
        ),
      );
    });
  }
}

/// Transparent text field with accent-colored focus border.
class _CinematicTextField extends StatefulWidget {
  const _CinematicTextField({
    required this.controller,
    required this.label,
    required this.accent,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final Color accent;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  State<_CinematicTextField> createState() => _CinematicTextFieldState();
}

class _CinematicTextFieldState extends State<_CinematicTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
    child: AnimatedContainer(
      duration: AppDurations.buttonHover,
      curve: CinematicCurves.hoverLift,
      decoration: BoxDecoration(
        color: _focused
            ? widget.accent.withValues(alpha: 0.04)
            : (Get.isDarkMode ? AppColors.backgroundLight.withValues(alpha: 0.3) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused
              ? widget.accent.withValues(alpha: 0.6)
              : (Get.isDarkMode ? Colors.white.withValues(alpha: 0.08) : AppColors.textSecondary.withValues(alpha: 0.2)),
          width: 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ]
            : (Get.isDarkMode ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]),
      ),
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        style: AppTypography.body.copyWith(color: AppColors.textBright),
        cursorColor: widget.accent,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: AppTypography.bodySmall.copyWith(
            color: _focused
                ? widget.accent
                : AppColors.textSecondary,
          ),
          floatingLabelStyle: AppTypography.caption.copyWith(
            color: widget.accent,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          errorStyle: AppTypography.caption.copyWith(
            color: AppColors.projAccent,
          ),
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    ),
  );
}

/// Submit button with loading state.
class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.accent,
    required this.label,
    required this.isSending,
    required this.onTap,
  });

  final Color accent;
  final String label;
  final bool isSending;
  final VoidCallback? onTap;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    cursor: widget.isSending
        ? SystemMouseCursors.forbidden
        : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppDurations.buttonHover,
        curve: CinematicCurves.hoverLift,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: widget.isSending
              ? widget.accent.withValues(alpha: 0.05)
              : _hovered
                  ? widget.accent.withValues(alpha: 0.12)
                  : widget.accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered && !widget.isSending
                ? widget.accent.withValues(alpha: 0.8)
                : widget.accent.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: _hovered && !widget.isSending
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.12),
                    blurRadius: 20,
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: widget.isSending
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(widget.accent),
                ),
              )
            : Text(
                widget.label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.accent,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    ),
  );
}
