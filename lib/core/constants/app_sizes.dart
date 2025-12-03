/// CJE Platform Size Constants
/// Consistent spacing, sizing, and dimensions throughout the app
class AppSizes {
  AppSizes._();

  // ============================================
  // SPACING (Padding, Margin, Gap)
  // ============================================

  static const double spacing0 = 0;
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing10 = 10;
  static const double spacing12 = 12;
  static const double spacing14 = 14;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing28 = 28;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing56 = 56;
  static const double spacing64 = 64;
  static const double spacing72 = 72;
  static const double spacing80 = 80;

  // Common spacing aliases
  static const double paddingXS = spacing4;
  static const double paddingSM = spacing8;
  static const double paddingMD = spacing16;
  static const double paddingLG = spacing24;
  static const double paddingXL = spacing32;
  static const double paddingXXL = spacing48;

  // Screen padding
  static const double screenPaddingHorizontal = spacing16;
  static const double screenPaddingVertical = spacing16;
  static const double screenPadding = spacing16;

  // ============================================
  // BORDER RADIUS
  // ============================================

  static const double radiusNone = 0;
  static const double radiusXS = 4;
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;
  static const double radiusFull = 999;

  // Component-specific radius
  static const double radiusButton = radiusMD;
  static const double radiusCard = radiusMD;
  static const double radiusInput = radiusSM;
  static const double radiusBadge = radiusFull;
  static const double radiusBottomSheet = radiusXL;
  static const double radiusDialog = radiusLG;

  // ============================================
  // ICON SIZES
  // ============================================

  static const double iconXS = 12;
  static const double iconSM = 16;
  static const double iconMD = 20;
  static const double iconLG = 24;
  static const double iconXL = 32;
  static const double iconXXL = 40;
  static const double iconHuge = 48;

  // Navigation icons
  static const double iconNav = iconLG;
  static const double iconAppBar = iconLG;
  static const double iconFab = iconLG;

  // ============================================
  // FONT SIZES
  // ============================================

  static const double fontXXS = 10;
  static const double fontXS = 12;
  static const double fontSM = 14;
  static const double fontMD = 16;
  static const double fontLG = 18;
  static const double fontXL = 20;
  static const double fontXXL = 24;
  static const double fontHuge = 28;
  static const double fontDisplay = 32;
  static const double fontDisplayLG = 40;

  // Text style specific
  static const double fontCaption = fontXS;
  static const double fontBody = fontMD;
  static const double fontSubtitle = fontLG;
  static const double fontTitle = fontXL;
  static const double fontHeadline = fontXXL;

  // ============================================
  // LINE HEIGHTS
  // ============================================

  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // ============================================
  // COMPONENT HEIGHTS
  // ============================================

  static const double buttonHeightSM = 36;
  static const double buttonHeightMD = 44;
  static const double buttonHeightLG = 52;
  static const double buttonHeight = buttonHeightMD;

  static const double inputHeight = 52;
  static const double inputHeightSM = 44;

  static const double appBarHeight = 56;
  static const double bottomNavHeight = 64;
  static const double fabSize = 56;
  static const double fabSizeMini = 40;

  static const double listTileHeight = 56;
  static const double listTileHeightSmall = 48;

  // ============================================
  // CARD SIZES
  // ============================================

  static const double cardElevation = 2;
  static const double cardElevationHover = 4;

  // ============================================
  // AVATAR SIZES
  // ============================================

  static const double avatarXS = 24;
  static const double avatarSM = 32;
  static const double avatarMD = 40;
  static const double avatarLG = 48;
  static const double avatarXL = 64;
  static const double avatarXXL = 80;
  static const double avatarHuge = 120;

  // ============================================
  // BADGE SIZES
  // ============================================

  static const double badgeHeight = 20;
  static const double badgeHeightSM = 16;
  static const double badgePaddingH = spacing8;
  static const double badgePaddingV = spacing4;

  // ============================================
  // BORDER WIDTH
  // ============================================

  static const double borderWidth = 1;
  static const double borderWidthMD = 1.5;
  static const double borderWidthLG = 2;

  // ============================================
  // DIVIDER
  // ============================================

  static const double dividerThickness = 1;
  static const double dividerIndent = spacing16;

  // ============================================
  // MAX WIDTHS
  // ============================================

  static const double maxWidthMobile = 480;
  static const double maxWidthTablet = 768;
  static const double maxWidthDesktop = 1200;
  static const double maxWidthContent = 600;

  // ============================================
  // ANIMATION DURATIONS (in milliseconds)
  // ============================================

  static const int animDurationFast = 150;
  static const int animDurationNormal = 300;
  static const int animDurationSlow = 500;

  // Duration objects
  static const Duration animFast = Duration(milliseconds: animDurationFast);
  static const Duration animNormal = Duration(milliseconds: animDurationNormal);
  static const Duration animSlow = Duration(milliseconds: animDurationSlow);

  // ============================================
  // SHIMMER / SKELETON
  // ============================================

  static const double shimmerHeight = 16;
  static const double shimmerHeightLG = 20;
  static const double shimmerCardHeight = 120;

  // ============================================
  // BOTTOM SHEET
  // ============================================

  static const double bottomSheetHandleWidth = 40;
  static const double bottomSheetHandleHeight = 4;
  static const double bottomSheetMinHeight = 200;

  // ============================================
  // SNACKBAR / TOAST
  // ============================================

  static const double snackbarMaxWidth = 400;
  static const int snackbarDuration = 3000; // milliseconds
}
