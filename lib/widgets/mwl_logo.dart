import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Logo Emblem "MWL" milik MyWatchList.
///
/// Terdiri atas:
/// * Busur sabit ganda atas (busur luar tebal + busur dalam tipis) yang terpotong
///   rata horizontal di kiri dan meruncing tajam di kanan.
/// * Busur sabit ganda bawah (cerminan simetris dari busur atas).
/// * Monogram "MWL" geometris ekstra tebal dengan puncak M & W yang membulat.
///
/// Seluruh elemen digambar sebagai vektor menggunakan [CustomPainter] sehingga
/// tajam di semua ukuran dan dapat dianimasikan lewat [animationProgress]:
/// * 0.00 â€“ 0.67 : busur sabit digambar melingkar (sweep via PathMetrics).
/// * 0.50 â€“ 1.00 : monogram "MWL" muncul dengan efek scale & fade-in.
///
/// Warna otomatis menyesuaikan tema:
/// * Dark Mode  : lingkaran biru (#0094FF) + subtle glow biru, elemen putih.
/// * Light Mode : lingkaran putih bersih, elemen hitam pekat (#0D0D0D).
class MwlLogo extends StatelessWidget {
  /// Warna aksen biru utama aplikasi.
  static const Color brandBlue = Color(0xFF0094FF);

  /// Warna hitam pekat untuk elemen logo pada Light Mode.
  static const Color ink = Color(0xFF0D0D0D);

  /// Ukuran sisi logo (lebar = tinggi).
  final double size;

  /// Warna elemen (busur & teks) kustom. Jika null, mengikuti tema.
  final Color? customColor;

  /// Progres animasi logo dari 0.0 (kosong) hingga 1.0 (utuh).
  final double animationProgress;

  /// Tampilkan lingkaran emblem di belakang elemen logo.
  final bool showBackground;

  /// Paksa brightness tertentu. Jika null, memakai `Theme.of(context).brightness`.
  final Brightness? brightness;

  const MwlLogo({
    super.key,
    this.size = 80,
    this.customColor,
    this.animationProgress = 1.0,
    this.showBackground = true,
    this.brightness,
  }) : assert(size > 0);

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        (brightness ?? Theme.of(context).brightness) == Brightness.dark;

    return Semantics(
      image: true,
      label: 'Logo MyWatchList',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: MwlLogoPainter.themed(
            isDark: isDark,
            customColor: customColor,
            showBackground: showBackground,
            progress: animationProgress,
          ),
        ),
      ),
    );
  }
}

/// Spesifikasi satu busur sabit (dalam ruang desain 100 x 100).
class _MwlBand {
  final double outerRadius;
  final double width;
  final double endAngle; // radian, relatif terhadap sumbu horizontal kanan

  const _MwlBand(this.outerRadius, this.width, this.endAngle);
}

/// CustomPainter untuk emblem "MWL".
///
/// Semua geometri didefinisikan pada kanvas desain 100 x 100 lalu diskalakan,
/// sehingga hasilnya presisi pada ukuran berapa pun.
class MwlLogoPainter extends CustomPainter {
  final Color elementColor;
  final Color? backgroundStart;
  final Color? backgroundEnd;
  final Color? glowColor;
  final Color? shadowColor;
  final Color? rimColor;
  final double progress;

  const MwlLogoPainter({
    required this.elementColor,
    this.backgroundStart,
    this.backgroundEnd,
    this.glowColor,
    this.shadowColor,
    this.rimColor,
    this.progress = 1.0,
  });

  /// Membuat painter dengan palet warna adaptif Dark / Light Mode.
  factory MwlLogoPainter.themed({
    required bool isDark,
    Color? customColor,
    bool showBackground = true,
    double progress = 1.0,
  }) {
    if (!showBackground) {
      return MwlLogoPainter(
        elementColor: customColor ?? (isDark ? MwlLogo.brandBlue : MwlLogo.ink),
        glowColor: isDark ? const Color(0x400094FF) : null,
        progress: progress,
      );
    }

    if (isDark) {
      // Mode Gelap: lingkaran biru bergradasi + glow biru, elemen putih bersih.
      return MwlLogoPainter(
        elementColor: customColor ?? Colors.white,
        backgroundStart: const Color(0xFF3BB4FF),
        backgroundEnd: const Color(0xFF0072DB),
        glowColor: const Color(0x990094FF),
        rimColor: const Color(0x38FFFFFF),
        progress: progress,
      );
    }

    // Mode Terang: lingkaran putih bersih, elemen hitam pekat #0D0D0D.
    return MwlLogoPainter(
      elementColor: customColor ?? MwlLogo.ink,
      backgroundStart: Colors.white,
      backgroundEnd: const Color(0xFFF2F4F7),
      shadowColor: const Color(0x24000000),
      rimColor: const Color(0x14000000),
      progress: progress,
    );
  }

  // ---------------------------------------------------------------------------
  // GEOMETRI (ruang desain 100 x 100, pusat di (50, 50))
  // ---------------------------------------------------------------------------
  static const Offset _center = Offset(50, 50);

  /// Jarak vertikal potongan rata kiri dari garis tengah (sejajar tinggi teks).
  static const double _cutGap = 10.0;

  /// Busur luar (tebal) dan busur dalam (tipis, lebih pendek agar dinamis).
  static const List<_MwlBand> _bands = [
    _MwlBand(41.0, 8.5, -8 * math.pi / 180),
    _MwlBand(30.0, 4.2, -32 * math.pi / 180),
  ];

  static const double _textTop = 40.0;
  static const double _textBottom = 60.0;
  static const double _letterStroke = 5.0;

  /// Matriks pencerminan vertikal (y' = 100 - y) untuk busur bawah.
  static final Float64List _mirrorY = Float64List.fromList(const [
    1, 0, 0, 0, //
    0, -1, 0, 0, //
    0, 0, 1, 0, //
    0, 100, 0, 1, //
  ]);

  /// Ketebalan busur sepanjang lintasan: rata di awal, lalu meruncing ke 0.
  static double _taper(double t, double width) {
    const double flat = 0.12;
    if (t <= flat) return width;
    final double u = ((t - flat) / (1 - flat)).clamp(0.0, 1.0);
    return width * (1 - math.pow(u, 1.6).toDouble());
  }

  /// Bentuk busur sabit atas: tepi luar lingkaran sempurna, tepi dalam
  /// meruncing; ujung kiri dipotong rata horizontal di y = 50 - [_cutGap].
  static Path _buildBand(_MwlBand band) {
    final double ro = band.outerRadius;
    final double ri = ro - band.width;
    final double a0 = math.pi + math.asin(_cutGap / ro);
    final double ai0 = math.pi + math.asin(_cutGap / ri);
    final double a1 = 2 * math.pi + band.endAngle;

    final Path path = Path()
      ..moveTo(_center.dx + ro * math.cos(a0), _center.dy + ro * math.sin(a0))
      ..arcTo(Rect.fromCircle(center: _center, radius: ro), a0, a1 - a0, false);

    const int steps = 96;
    for (int i = steps; i >= 0; i--) {
      final double a = ai0 + (a1 - ai0) * i / steps;
      final double t = (a - a0) / (a1 - a0);
      final double r = ro - _taper(t, band.width);
      path.lineTo(_center.dx + r * math.cos(a), _center.dy + r * math.sin(a));
    }
    return path..close();
  }

  /// Lintasan panduan (garis tengah busur) untuk animasi sweep via PathMetrics.
  static Path _buildGuide(_MwlBand band) {
    final double rc = band.outerRadius - band.width / 2;
    const double start = math.pi - 0.08;
    final double end = 2 * math.pi + band.endAngle + 0.08;
    return Path()
      ..addArc(Rect.fromCircle(center: _center, radius: rc), start, end - start);
  }

  static final List<Path> _arcShapes = [
    for (final band in _bands) _buildBand(band),
    for (final band in _bands) _buildBand(band).transform(_mirrorY),
  ];

  static final List<Path> _arcGuides = [
    for (final band in _bands) _buildGuide(band),
    for (final band in _bands) _buildGuide(band).transform(_mirrorY),
  ];

  static final List<double> _arcWidths = [
    for (final band in _bands) band.width,
    for (final band in _bands) band.width,
  ];

  /// Huruf M: kaki tegak, puncak membulat (round join), lembah di tengah.
  static final Path _mPath = Path()
    ..moveTo(24.5, 63)
    ..lineTo(24.5, 42.5)
    ..lineTo(31.5, 54.5)
    ..lineTo(38.5, 42.5)
    ..lineTo(38.5, 63);

  /// Huruf W: empat diagonal dengan puncak tengah membulat.
  static final Path _wPath = Path()
    ..moveTo(44.98, 37)
    ..lineTo(49.2, 57.5)
    ..lineTo(54.5, 46.5)
    ..lineTo(59.8, 57.5)
    ..lineTo(64.02, 37);

  /// Huruf L: sudut siku tegas.
  static final Path _lPath = Path()
    ..moveTo(70.5, 37)
    ..lineTo(70.5, 57.5)
    ..lineTo(78, 57.5);

  /// Empat bentuk busur sabit (atas-luar, atas-dalam, bawah-luar, bawah-dalam).
  static List<Path> get arcPaths => List.unmodifiable(_arcShapes);

  /// Lintasan monogram M, W, L.
  static List<Path> get monogramPaths =>
      List.unmodifiable([_mPath, _wPath, _lPath]);

  static double _interval(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  static Color _fade(Color color, double opacity) =>
      color.withValues(alpha: color.a * opacity.clamp(0.0, 1.0));

  // ---------------------------------------------------------------------------
  // PAINT
  // ---------------------------------------------------------------------------
  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height) / 100.0;
    if (s <= 0) return;

    final double p = progress.clamp(0.0, 1.0);
    final double bgT = _interval(p, 0.0, 0.22);
    final double arcT = _interval(p, 0.0, 2 / 3);
    final double textT = _interval(p, 0.5, 1.0);

    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);

    // 1. Latar emblem (digambar di ruang piksel agar blur konsisten).
    if (bgT > 0) _paintBackground(canvas, s, bgT);

    canvas.scale(s);

    // 2. Busur sabit ganda atas & bawah.
    if (arcT > 0) _paintArcs(canvas, arcT);

    // 3. Monogram "MWL".
    if (textT > 0) _paintMonogram(canvas, textT);

    canvas.restore();
  }

  void _paintBackground(Canvas canvas, double s, double t) {
    final double scale = Curves.easeOutBack.transform(t);
    final double opacity = Curves.easeOut.transform(t);
    final Offset c = _center * s;
    final double r = 50 * s * scale;
    final bool hasDisc = backgroundStart != null && backgroundEnd != null;

    if (glowColor != null) {
      canvas.drawCircle(
        c,
        hasDisc ? r * 0.94 : r * 0.7,
        Paint()
          ..color = _fade(glowColor!, opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * s),
      );
    }

    if (!hasDisc) return;

    if (shadowColor != null) {
      canvas.drawCircle(
        c + Offset(0, 2.5 * s * scale),
        r * 0.97,
        Paint()
          ..color = _fade(shadowColor!, opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * s),
      );
    }

    final Rect discRect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _fade(backgroundStart!, opacity),
            _fade(backgroundEnd!, opacity),
          ],
        ).createShader(discRect),
    );

    if (rimColor != null) {
      canvas.drawCircle(
        c,
        r - 0.5 * s,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * s
          ..color = _fade(rimColor!, opacity),
      );
    }
  }

  void _paintArcs(Canvas canvas, double t) {
    final Paint fill = Paint()
      ..color = elementColor
      ..isAntiAlias = true;

    for (int i = 0; i < _arcShapes.length; i++) {
      // Busur dalam sedikit tertinggal dari busur luar agar terasa mengalir.
      final bool isInner = i.isOdd;
      final double local = Curves.easeInOutCubic.transform(
        isInner ? _interval(t, 0.15, 1.0) : _interval(t, 0.0, 0.85),
      );
      if (local <= 0) continue;

      final Path shape = _arcShapes[i];
      if (local >= 1) {
        canvas.drawPath(shape, fill);
        continue;
      }

      // Sweep: ambil sebagian garis tengah busur dengan PathMetrics, lalu
      // gunakan sebagai masker (dstIn) terhadap bentuk sabit penuh.
      final Path revealed = Path();
      for (final PathMetric metric in _arcGuides[i].computeMetrics()) {
        revealed.addPath(
          metric.extractPath(0, metric.length * local),
          Offset.zero,
        );
      }

      canvas.saveLayer(shape.getBounds().inflate(2), Paint());
      canvas.drawPath(shape, fill);
      canvas.drawPath(
        revealed,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _arcWidths[i] + 6
          ..strokeCap = StrokeCap.butt
          ..blendMode = BlendMode.dstIn,
      );
      canvas.restore();
    }
  }

  void _paintMonogram(Canvas canvas, double t) {
    final double scale = 0.55 + 0.45 * Curves.easeOutBack.transform(t);
    final double opacity = Curves.easeOut.transform(_interval(t, 0.0, 0.6));
    if (opacity <= 0) return;

    canvas.save();
    canvas.translate(_center.dx, _center.dy);
    canvas.scale(scale);
    canvas.translate(-_center.dx, -_center.dy);
    // Potong ujung atas/bawah huruf agar rata pada garis baseline & cap-height.
    canvas.clipRect(const Rect.fromLTRB(0, _textTop, 100, _textBottom));

    final Paint stroke = Paint()
      ..color = _fade(elementColor, opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _letterStroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(_mPath, stroke);
    canvas.drawPath(_wPath, stroke);
    canvas.drawPath(_lPath, stroke..strokeJoin = StrokeJoin.miter);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MwlLogoPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.elementColor != elementColor ||
      oldDelegate.backgroundStart != backgroundStart ||
      oldDelegate.backgroundEnd != backgroundEnd ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.rimColor != rimColor;
}
