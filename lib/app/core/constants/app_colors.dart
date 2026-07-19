import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Centralized color palette for the cinematic portfolio theme.
final class AppColors {
  const AppColors._();

  // ─── Base ───────────────────────────────────────────────────────────
  static Color get background => Get.isDarkMode ? const Color(0xFF030014) : const Color(0xFFFAFAFC);
  static Color get backgroundDark => Get.isDarkMode ? const Color(0xFF010008) : const Color(0xFFF1F5F9);
  static Color get backgroundLight => Get.isDarkMode ? const Color(0xFF0F0A2A) : const Color(0xFFFFFFFF);
  static Color get backgroundHover => Get.isDarkMode ? const Color(0xFF1A1145) : const Color(0xFFE2E8F0);

  // ─── Text hierarchy ─────────────────────────────────────────────────
  static Color get textBright => Get.isDarkMode ? const Color(0xFFE8ECF4) : const Color(0xFF0F172A);
  static Color get textPrimary => Get.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF1E293B);
  static Color get textSecondary => Get.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569);
  static const Color white = Color(0xFFF8FAFC);

  // ─── Scene: Hero — Blade Runner 2049 ──────────────────────────────
  static Color get heroGradient1 => Get.isDarkMode ? const Color(0xFF1E0B3E) : const Color(0xFFF0F9FF);
  static Color get heroGradient2 => Get.isDarkMode ? const Color(0xFF2D1055) : const Color(0xFFE0F2FE);
  static Color get heroGradient3 => Get.isDarkMode ? const Color(0xFF0891B2) : const Color(0xFFBAE6FD);
  static Color get heroAccent => Get.isDarkMode ? const Color(0xFF06B6D4) : const Color(0xFF0284C7);

  // ─── Scene: About — Dune ──────────────────────────────────────────
  static Color get aboutGradient1 => Get.isDarkMode ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);
  static Color get aboutGradient2 => Get.isDarkMode ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
  static Color get aboutGradient3 => Get.isDarkMode ? const Color(0xFF1E1B4B) : const Color(0xFFFDE68A);
  static Color get aboutAccent => Get.isDarkMode ? const Color(0xFFF59E0B) : const Color(0xFFD97706);

  // ─── Scene: Experience — Matrix ────────────────────────────────────
  static Color get expGradient1 => Get.isDarkMode ? const Color(0xFF0F4C4C) : const Color(0xFFF0FDF4);
  static Color get expGradient2 => Get.isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
  static Color get expGradient3 => Get.isDarkMode ? const Color(0xFF78350F) : const Color(0xFFBBF7D0);
  static Color get expAccent => Get.isDarkMode ? const Color(0xFF10B981) : const Color(0xFF059669);

  // ─── Scene: Projects — Spider-Verse ────────────────────────────────
  static Color get projGradient1 => Get.isDarkMode ? const Color(0xFF831843) : const Color(0xFFFFF1F2);
  static Color get projGradient2 => Get.isDarkMode ? const Color(0xFF9F1239) : const Color(0xFFFFE4E6);
  static Color get projGradient3 => Get.isDarkMode ? const Color(0xFF0C1445) : const Color(0xFFFECDD3);
  static Color get projAccent => Get.isDarkMode ? const Color(0xFFF43F5E) : const Color(0xFFE11D48);

  // ─── Scene: Contact — Interstellar ─────────────────────────────────
  static Color get contactGradient1 => Get.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC);
  static Color get contactGradient2 => Get.isDarkMode ? const Color(0xFF171717) : const Color(0xFFF1F5F9);
  static Color get contactGradient3 => Get.isDarkMode ? const Color(0xFF1C1C1C) : const Color(0xFFE2E8F0);
  static Color get contactAccent => Get.isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  // ─── Semantic aliases ──────────────────────────────────────────────
  static Color get accent => Get.isDarkMode ? heroAccent : const Color(0xFF0284C7);
  static Color get accentMuted => Get.isDarkMode ? const Color(0x1A06B6D4) : const Color(0x1A0284C7);
  static Color get primary => accent;
  static Color get surface => backgroundLight;
  static Color get surfaceVariant => backgroundLight;
}
