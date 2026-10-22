import 'package:flutter/material.dart';

/// Tokens visuais centrais do UNEX PLAY.
/// A paleta prioriza superfícies escuras e acentos roxo/azul; efeitos de vidro
/// devem ser usados apenas em overlays e áreas de navegação, não em toda a grade.
abstract final class UnexDesignTokens {
  static const Color background = Color(0xFF070A12);
  static const Color surface = Color(0xFF0D1421);
  static const Color surfaceElevated = Color(0xFF131D2D);
  static const Color surfaceGlass = Color(0xCC141B2B);
  static const Color primary = Color(0xFF8B70FF);
  static const Color secondary = Color(0xFF2F80FF);
  static const Color focus = Color(0xFFB9ACFF);
  static const Color live = Color(0xFFF0445B);
  static const Color success = Color(0xFF37C995);
  static const Color textPrimary = Color(0xFFF7F8FC);
  static const Color textSecondary = Color(0xFFA8B1C2);
  static const Color textDisabled = Color(0xFF737E92);
  static const Color borderSubtle = Color(0x1FFFFFFF);

  static const double radiusSmall = 12;
  static const double radiusCard = 16;
  static const double radiusPanel = 22;

  static const Duration motionFast = Duration(milliseconds: 140);
  static const Duration motionStandard = Duration(milliseconds: 180);
}
