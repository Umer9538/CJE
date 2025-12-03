import 'package:flutter/material.dart';

/// CJE Platform Color System
/// Based on the official CJE Platform Color Guide
class AppColors {
  AppColors._();

  // ============================================
  // LIGHT MODE COLORS
  // ============================================

  /// Primary - Deep Navy Blue (#0B1F3A)
  /// Usage: Main brand color, buttons, AppBar
  static const Color primaryLight = Color(0xFF0B1F3A);

  /// Secondary - Golden Yellow (#D4AF37)
  /// Usage: Accent color, highlights, badges
  static const Color secondaryLight = Color(0xFFD4AF37);

  /// Background - Light Gray (#FAFAFA)
  /// Usage: Screen backgrounds
  static const Color backgroundLight = Color(0xFFFAFAFA);

  /// Surface - Light Gray (#FAFAFA)
  /// Usage: Surface elements
  static const Color surfaceLight = Color(0xFFFAFAFA);

  /// Card Background - Pure White (#FFFFFF)
  /// Usage: Cards, modals, dialogs
  static const Color cardLight = Color(0xFFFFFFFF);

  /// Border - Light Border Gray (#E5E7EB)
  /// Usage: Dividers, card borders
  static const Color borderLight = Color(0xFFE5E7EB);

  /// Text Primary - Dark Gray (#111827)
  /// Usage: Main text, headings
  static const Color textPrimaryLight = Color(0xFF111827);

  /// Text on Primary - White (#FFFFFF)
  /// Usage: Text on primary color buttons
  static const Color textOnPrimaryLight = Color(0xFFFFFFFF);

  /// Error - Red (#DC2626)
  /// Usage: Error messages, validation
  static const Color errorLight = Color(0xFFDC2626);

  /// Tertiary - Medium Gray (#6B7280)
  /// Usage: Secondary text, icons, hints
  static const Color tertiaryLight = Color(0xFF6B7280);

  // ============================================
  // DARK MODE COLORS
  // ============================================

  /// Primary - Golden Yellow (#D4AF37)
  /// Usage: Primary in dark mode
  static const Color primaryDark = Color(0xFFD4AF37);

  /// Secondary - Golden Yellow (#D4AF37)
  /// Usage: Accent color
  static const Color secondaryDark = Color(0xFFD4AF37);

  /// Background - Very Dark Blue-Gray (#111827)
  /// Usage: Screen backgrounds
  static const Color backgroundDark = Color(0xFF111827);

  /// Surface - Very Dark Blue-Gray (#111827)
  /// Usage: Surface elements
  static const Color surfaceDark = Color(0xFF111827);

  /// Card Background - Dark Gray (#1F2937)
  /// Usage: Cards, modals, dialogs
  static const Color cardDark = Color(0xFF1F2937);

  /// Border - Dark Border Gray (#374151)
  /// Usage: Dividers, card borders
  static const Color borderDark = Color(0xFF374151);

  /// Text Primary - Off White (#F9FAFB)
  /// Usage: Main text, headings
  static const Color textPrimaryDark = Color(0xFFF9FAFB);

  /// Text on Primary - Dark Gray (#1F2937)
  /// Usage: Text on golden buttons
  static const Color textOnPrimaryDark = Color(0xFF1F2937);

  /// Error - Light Red (#F87171)
  /// Usage: Error messages (lighter for visibility)
  static const Color errorDark = Color(0xFFF87171);

  /// Tertiary - Light Gray (#9CA3AF)
  /// Usage: Secondary text, icons, hints
  static const Color tertiaryDark = Color(0xFF9CA3AF);

  // ============================================
  // STATUS COLORS (Same for both modes)
  // ============================================

  /// Success - Light Mode (#10B981)
  static const Color successLight = Color(0xFF10B981);

  /// Success - Dark Mode (#34D399)
  static const Color successDark = Color(0xFF34D399);

  /// Warning - Light Mode (#F59E0B)
  static const Color warningLight = Color(0xFFF59E0B);

  /// Warning - Dark Mode (#FBBF24)
  static const Color warningDark = Color(0xFFFBBF24);

  /// Info - Light Mode (#3B82F6)
  static const Color infoLight = Color(0xFF3B82F6);

  /// Info - Dark Mode (#60A5FA)
  static const Color infoDark = Color(0xFF60A5FA);

  // ============================================
  // INITIATIVE STATUS COLORS
  // ============================================

  /// Proposed - Blue (#3B82F6)
  static const Color initiativeProposed = Color(0xFF3B82F6);

  /// In Debate - Orange (#F59E0B)
  static const Color initiativeDebate = Color(0xFFF59E0B);

  /// Adopted - Green (#10B981)
  static const Color initiativeAdopted = Color(0xFF10B981);

  /// Rejected - Red (#DC2626)
  static const Color initiativeRejected = Color(0xFFDC2626);

  /// Draft - Gray (#6B7280)
  static const Color initiativeDraft = Color(0xFF6B7280);

  /// Submitted - Blue (#3B82F6)
  static const Color initiativeSubmitted = Color(0xFF3B82F6);

  /// Review - Purple (#8B5CF6)
  static const Color initiativeReview = Color(0xFF8B5CF6);

  /// Voting - Orange (#F59E0B)
  static const Color initiativeVoting = Color(0xFFF59E0B);

  // ============================================
  // MEETING TYPE COLORS
  // ============================================

  /// County AG - Primary Navy (#0B1F3A)
  static const Color meetingCountyAG = Color(0xFF0B1F3A);

  /// County AG Accent - Gold (#D4AF37)
  static const Color meetingCountyAGAccent = Color(0xFFD4AF37);

  /// BEX - Red (#DC2626)
  static const Color meetingBEX = Color(0xFFDC2626);

  /// Department - Gold (#D4AF37)
  static const Color meetingDepartment = Color(0xFFD4AF37);

  /// School - Gray (#6B7280)
  static const Color meetingSchool = Color(0xFF6B7280);

  // ============================================
  // ROLE BADGE COLORS
  // ============================================

  // Student Badge
  static const Color badgeStudentBg = Color(0xFFE5E7EB);
  static const Color badgeStudentText = Color(0xFF374151);

  // Class Rep Badge
  static const Color badgeClassRepBg = Color(0xFFDBEAFE);
  static const Color badgeClassRepText = Color(0xFF1D4ED8);

  // School Rep Badge - Gold with 20% opacity
  static const Color badgeSchoolRepBg = Color(0x33D4AF37); // 20% opacity
  static const Color badgeSchoolRepText = Color(0xFF0B1F3A);

  // Department Badge
  static const Color badgeDepartmentBg = Color(0xFFFEF3C7);
  static const Color badgeDepartmentText = Color(0xFFD97706);

  // BEX Badge
  static const Color badgeBEXBg = Color(0xFFD4AF37);
  static const Color badgeBEXText = Color(0xFF0B1F3A);

  // Superadmin Badge
  static const Color badgeSuperadminBg = Color(0xFF0B1F3A);
  static const Color badgeSuperadminText = Color(0xFFFFFFFF);

  // ============================================
  // DOCUMENT CATEGORY COLORS
  // ============================================

  static const Color docStatutElevului = Color(0xFF3B82F6);
  static const Color docRegulamente = Color(0xFF10B981);
  static const Color docMetodologii = Color(0xFFF59E0B);
  static const Color docFormulare = Color(0xFF8B5CF6);

  // ============================================
  // COMMON COLORS
  // ============================================

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  /// Golden Yellow - Brand accent
  static const Color gold = Color(0xFFD4AF37);

  /// Navy Blue - Brand primary
  static const Color navy = Color(0xFF0B1F3A);
}
