import 'package:flutter/material.dart';

class AppTheme {
  // ── Palet Islami ──
  static const Color hijauEmerald = Color(0xFF1A6B4A);
  static const Color hijauMuda = Color(0xFF2E9B6F);
  static const Color hijauTerang = Color(0xFF3DBE8B);
  static const Color emas = Color(0xFFCFA84C);
  static const Color emasTerang = Color(0xFFE8C56D);
  static const Color krem = Color(0xFFFDF8F0);
  static const Color kremGelap = Color(0xFFF5EDD8);
  static const Color coklat = Color(0xFF7A5C2E);
  static const Color abuAbu = Color(0xFF6B7280);
  static const Color putih = Color(0xFFFFFFFF);
  static const Color hitamLembut = Color(0xFF1C2526);
  static const Color merahError = Color(0xFFDC2626);
  static const Color birInfo = Color(0xFF2563EB);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: hijauEmerald,
        brightness: Brightness.light,
        primary: hijauEmerald,
        secondary: emas,
        surface: krem,
        background: kremGelap,
      ),
      scaffoldBackgroundColor: kremGelap,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: hijauEmerald,
        foregroundColor: putih,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: putih,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: hijauEmerald,
          foregroundColor: putih,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: putih,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hijauEmerald, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: abuAbu),
      ),
      cardTheme: CardThemeData(
        color: putih,
        elevation: 0,
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: kremGelap,
        selectedColor: hijauEmerald.withOpacity(0.15),
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
    );
  }
}

// ── Widget dekoratif arabesque/islami ──
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 40.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        _drawStar(canvas, paint, Offset(x, y), 10);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double r) {
    const points = 8;
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * 3.14159 / points) - 3.14159 / 2;
      final radius = i.isEven ? r : r * 0.45;
      final x = center.dx + radius * _cos(angle);
      final y = center.dy + radius * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double a) => _approxCos(a);
  double _sin(double a) => _approxSin(a);

  double _approxCos(double x) {
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 6; i++) {
      term *= -x * x / (2 * i * (2 * i - 1));
      result += term;
    }
    return result;
  }

  double _approxSin(double x) {
    double result = x;
    double term = x;
    for (int i = 1; i <= 6; i++) {
      term *= -x * x / ((2 * i + 1) * (2 * i));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
