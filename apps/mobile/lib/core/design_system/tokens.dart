import 'package:flutter/material.dart';
export 'ws_glyph.dart';

/// Design tokens defining colors, typography, and visual styling for W's.
class WColors {
  // Brand Accents
  static const Color brandPrimary = Color(0xFFFF5722); // Deep Amber/Flame Orange
  static const Color brandPrimaryLight = Color(0xFFFF8A50);
  static const Color brandAccent = Color(0xFF7C4DFF); // Electric Momentum Purple
  static const Color brandAccentGlow = Color(0x667C4DFF);

  // Backgrounds & Surfaces (OLED Dark Mode)
  static const Color background = Color(0xFF0A0A0E);
  static const Color surface = Color(0xFF14141A);
  static const Color surfaceElevated = Color(0xFF1E1E28);
  static const Color surfaceGlass = Color(0x33282838);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B2);
  static const Color textTertiary = Color(0xFF65657A);

  // Status & Badges
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF3D00);
  static const Color warning = Color(0xFFFFC107);
  static const Color verifiedBadge = Color(0xFF29B6F6); // Blue checkmark

  // Collectible Rarity
  static const Color rarityCommon = Color(0xFFB0BEC5);
  static const Color rarityRare = Color(0xFF29B6F6);
  static const Color rarityEpic = Color(0xFFAB47BC);
  static const Color rarityLegendary = Color(0xFFFFD700); // Gold
}

/// Token constants for W's TikTok-inspired Dark & Gold design system.
class WsTokens {
  static const Color surfaceBlack = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF121216);
  static const Color surfaceCard = Color(0xFF1A1A22);
  static const Color surfaceElevated = Color(0xFF222430);

  // Accent Colors
  static const Color brandGold = Color(0xFFFFD700);     // Neon Gold/Amber
  static const Color brandEmerald = Color(0xFF00E676);  // Growth Green
  static const Color brandFlame = Color(0xFFFF4500);    // Daily Streak Flame
  static const Color tiktokCyan = Color(0xFF00F2FE);    // Dynamic create pill left accent
  static const Color tiktokPink = Color(0xFFFE0979);    // Dynamic create pill right accent
  static const Color brandRose = Color(0xFFFE0979);

  // Typography Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B2);
  static const Color textMuted = Color(0xFF707080);
  static const Color divider = Color(0xFF2A2A35);
  static const Color verifiedBadge = Color(0xFF29B6F6);
}

class WSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class WRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double pill = 999.0;
}

/// Canonical design token aliases for feature views
class AppColors {
  static const Color background = Color(0xFF0A0A0E);
  static const Color surface = Color(0xFF14141A);
  static const Color surfaceBorder = Color(0xFF282838);
  static const Color neonGold = Color(0xFFFFD700);
  static const Color emeraldSuccess = Color(0xFF00E676);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B2);
  static const Color textTertiary = Color(0xFF65657A);
  static const Color crimsonError = Color(0xFFFF334B);
  static const Color cardSurface = Color(0xFF1A1A22);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double full = 999.0;
}

class AppTypography {
  static const TextStyle displayMedium = TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold);
  static const TextStyle titleLarge = TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);
  static const TextStyle titleMedium = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle titleSmall = TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600);
  static const TextStyle bodyLarge = TextStyle(color: Colors.white, fontSize: 16);
  static const TextStyle bodyMedium = TextStyle(color: Colors.white, fontSize: 14);
  static const TextStyle bodySmall = TextStyle(color: Colors.white70, fontSize: 12);
  static const TextStyle labelSmall = TextStyle(color: Colors.white60, fontSize: 11);
  static const TextStyle labelMedium = TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500);
}
