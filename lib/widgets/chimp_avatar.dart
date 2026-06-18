import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Estados de ánimo de Chimpy. Cambian la expresión (sonrisa, cejas, boca).
enum ChimpMood { neutral, happy, excited, thinking }

/// Avatar de un chimpancé dibujado a mano con [CustomPainter] (sin assets).
///
/// Es interactivo y vivo:
///  - parpadea solo cada pocos segundos,
///  - los ojos se mueven con un leve vaivén (mira alrededor),
///  - sonríe / abre la boca según [mood] y [talking],
///  - rebota cuando cambia [reactTrigger] (p. ej. al tocarlo o al recibir
///    un mensaje) y al tocarlo dispara [onTap].
class ChimpAvatar extends StatefulWidget {
  final double size;
  final ChimpMood mood;
  final bool talking;

  /// Cambiar este valor (incrementarlo) dispara una reacción de rebote.
  final int reactTrigger;
  final VoidCallback? onTap;

  const ChimpAvatar({
    super.key,
    this.size = 56,
    this.mood = ChimpMood.neutral,
    this.talking = false,
    this.reactTrigger = 0,
    this.onTap,
  });

  @override
  State<ChimpAvatar> createState() => _ChimpAvatarState();
}

class _ChimpAvatarState extends State<ChimpAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _blink;
  late final AnimationController _idle; // vaivén de la mirada
  late final AnimationController _talk;
  late final AnimationController _bounce;
  Timer? _blinkTimer;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _idle = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _talk = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _scheduleBlink();
    if (widget.talking) _talk.repeat(reverse: true);
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2200 + _rng.nextInt(2800)),
      () async {
        if (!mounted) return;
        await _blink.forward();
        await _blink.reverse();
        _scheduleBlink();
      },
    );
  }

  @override
  void didUpdateWidget(ChimpAvatar old) {
    super.didUpdateWidget(old);
    if (widget.reactTrigger != old.reactTrigger) {
      _bounce.forward(from: 0);
    }
    if (widget.talking != old.talking) {
      if (widget.talking) {
        _talk.repeat(reverse: true);
      } else {
        _talk.stop();
        _talk.animateTo(0, duration: const Duration(milliseconds: 120));
      }
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blink.dispose();
    _idle.dispose();
    _talk.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenable =
        Listenable.merge([_blink, _idle, _talk, _bounce]);
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) {
          // Rebote: 0→1→0 con un pequeño "pop".
          final b = Curves.elasticOut.transform(_bounce.value);
          final pop = widget.reactTrigger > 0 ? b : 0.0;
          final scale = 1 + 0.10 * pop * (1 - _bounce.value * 0.0);
          final lift = -6.0 * math.sin(_bounce.value * math.pi);

          final mouthOpen = widget.talking ? 0.25 + _talk.value * 0.75 : 0.0;
          final smile = switch (widget.mood) {
            ChimpMood.excited => 1.0,
            ChimpMood.happy => 0.7,
            ChimpMood.thinking => 0.0,
            ChimpMood.neutral => 0.35,
          };
          final lookX = math.sin(_idle.value * math.pi * 2) * 0.35;
          final lookY = math.cos(_idle.value * math.pi * 2) * 0.18 +
              (widget.mood == ChimpMood.thinking ? -0.45 : 0);

          return Transform.translate(
            offset: Offset(0, lift),
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _ChimpPainter(
                    blink: _blink.value,
                    mouthOpen: mouthOpen,
                    smile: smile,
                    lookX: lookX,
                    lookY: lookY,
                    excited: widget.mood == ChimpMood.excited,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChimpPainter extends CustomPainter {
  final double blink; // 0 abierto · 1 cerrado
  final double mouthOpen; // 0 cerrada · 1 abierta
  final double smile; // 0 seria · 1 gran sonrisa
  final double lookX; // -1..1
  final double lookY; // -1..1
  final bool excited;

  _ChimpPainter({
    required this.blink,
    required this.mouthOpen,
    required this.smile,
    required this.lookX,
    required this.lookY,
    required this.excited,
  });

  // Paleta cálida con varios tonos para dar volumen (luz arriba-izquierda,
  // sombra abajo-derecha). Bebé chimpancé realista pero tierno.
  static const _furHi = Color(0xFF9A7150); // pelo iluminado
  static const _furMid = Color(0xFF7A5839); // pelo base
  static const _furShadow = Color(0xFF553D28); // pelo en sombra
  static const _skinHi = Color(0xFFF4DBBB); // piel iluminada
  static const _skin = Color(0xFFE3C29B); // piel base
  static const _skinShade = Color(0xFFC29B72); // piel en sombra
  static const _ink = Color(0xFF241712); // ojo/nariz
  static const _iris = Color(0xFF6B4427); // iris cálido
  static const _irisDark = Color(0xFF35200F); // borde del iris
  static const _blush = Color(0xFFE38E7B);
  static const _tongue = Color(0xFFCE7E78);

  // Pseudo-aleatorio determinista (sin Random, para no titilar entre frames).
  double _noise(int i) {
    final v = math.sin(i * 12.9898) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s * 0.5;
    final cy = s * 0.5;

    // ── Orejas con volumen ───────────────────────────────────────────────
    final earR = s * 0.15;
    for (final sgn in [-1.0, 1.0]) {
      final ec = Offset(cx + sgn * s * 0.33, cy - s * 0.13);
      final earRect = Rect.fromCircle(center: ec, radius: earR);
      canvas.drawCircle(
          ec,
          earR,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-0.3, -0.4),
              colors: [_furHi, _furMid, _furShadow],
              stops: [0, 0.6, 1],
            ).createShader(earRect));
      canvas.drawCircle(ec, earR * 0.6, Paint()..color = _skinShade);
      canvas.drawCircle(
          ec.translate(0, -earR * 0.06), earR * 0.34, Paint()..color = _skin);
    }

    // ── Cabeza con sombreado esférico ────────────────────────────────────
    final headRect = Rect.fromCenter(
        center: Offset(cx, cy), width: s * 0.76, height: s * 0.74);
    canvas.drawOval(
        headRect,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.35, -0.45),
            radius: 1.0,
            colors: [_furHi, _furMid, _furShadow],
            stops: [0, 0.55, 1],
          ).createShader(headRect));

    // Textura de pelo: mechones cortos en el borde (silueta peluda).
    final rx = headRect.width / 2, ry = headRect.height / 2;
    const fluff = 54;
    for (int i = 0; i < fluff; i++) {
      final a = (2 * math.pi) * i / fluff;
      final dir = Offset(math.cos(a), math.sin(a));
      final base = Offset(cx + rx * 0.93 * dir.dx, cy + ry * 0.93 * dir.dy);
      final len = s * (0.02 + 0.045 * _noise(i));
      final tip = Offset(cx + (rx + len) * dir.dx, cy + (ry + len) * dir.dy);
      final lit = dir.dx < 0 && dir.dy < 0; // arriba-izquierda iluminado
      canvas.drawLine(
          base,
          tip,
          Paint()
            ..strokeWidth = s * 0.012
            ..strokeCap = StrokeCap.round
            ..color = (lit ? _furHi : _furShadow)
                .withValues(alpha: 0.55 + 0.4 * _noise(i + 7)));
    }

    // Ricito (ahoge) en la coronilla.
    final curl = Path()
      ..moveTo(cx - s * 0.015, headRect.top + s * 0.03)
      ..cubicTo(cx - s * 0.10, headRect.top - s * 0.04, cx + s * 0.07,
          headRect.top - s * 0.11, cx + s * 0.05, headRect.top + s * 0.01);
    canvas.drawPath(
        curl,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.026
          ..strokeCap = StrokeCap.round
          ..color = _furHi);

    // ── Carita (piel) con sombra ambiental y volumen ─────────────────────
    final faceRect = Rect.fromCenter(
        center: Offset(cx, cy + s * 0.09), width: s * 0.60, height: s * 0.58);
    // sombra que asienta la cara sobre el pelo
    canvas.drawOval(
        faceRect.translate(0, s * 0.012),
        Paint()
          ..color = _furShadow.withValues(alpha: 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02));
    canvas.drawOval(
        faceRect,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.2, -0.5),
            radius: 1.05,
            colors: [_skinHi, _skin, _skinShade],
            stops: [0, 0.6, 1],
          ).createShader(faceRect));

    final eyeY = cy + s * 0.05; // ojos bajos = esquema de bebé
    final eyeDX = s * 0.155;

    // Volumen del hocico: zona elevada y clara alrededor de nariz/boca.
    final muzzle = Rect.fromCenter(
        center: Offset(cx, eyeY + s * 0.16), width: s * 0.30, height: s * 0.26);
    canvas.drawOval(
        muzzle,
        Paint()
          ..color = _skinHi.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.025));

    // Cejas suaves (sombra sobre los ojos) → realismo sin dureza.
    for (final sgn in [-1.0, 1.0]) {
      final brow = Path()
        ..moveTo(cx + sgn * (eyeDX - s * 0.075), eyeY - s * 0.085)
        ..quadraticBezierTo(cx + sgn * eyeDX, eyeY - s * 0.115,
            cx + sgn * (eyeDX + s * 0.07), eyeY - s * 0.075);
      canvas.drawPath(
          brow,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.018
            ..strokeCap = StrokeCap.round
            ..color = _skinShade.withValues(alpha: 0.6)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.006));
    }

    // ── Cachetes con rubor ───────────────────────────────────────────────
    final blushA = excited ? 0.55 : 0.30;
    final blushR = excited ? s * 0.075 : s * 0.062;
    for (final sgn in [-1.0, 1.0]) {
      canvas.drawCircle(
          Offset(cx + sgn * s * 0.215, eyeY + s * 0.09),
          blushR,
          Paint()
            ..color = _blush.withValues(alpha: blushA)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02));
    }

    // ── Ojos grandes con iris realista ───────────────────────────────────
    final eyeW = s * 0.165, eyeH = s * 0.185;
    final maxShift = s * 0.013;
    for (final sgn in [-1.0, 1.0]) {
      final center = Offset(cx + sgn * eyeDX, eyeY);
      final opening = Rect.fromCenter(center: center, width: eyeW, height: eyeH);

      // ojera/cuenca: leve sombra alrededor para hundir el ojo
      canvas.drawOval(
          opening.inflate(s * 0.012),
          Paint()
            ..color = _skinShade.withValues(alpha: 0.55)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.012));

      canvas.save();
      canvas.clipPath(Path()..addOval(opening));
      canvas.drawOval(opening, Paint()..color = _skinHi); // esclera cálida
      final eyePos = center.translate(lookX * maxShift, lookY * maxShift);

      // iris con degradado
      final irisRect = Rect.fromCenter(
          center: eyePos, width: eyeW * 0.92, height: eyeH * 0.92);
      canvas.drawOval(
          irisRect,
          Paint()
            ..shader = const RadialGradient(
              colors: [_iris, _irisDark],
              stops: [0.45, 1],
            ).createShader(irisRect));
      // pupila
      canvas.drawOval(
          Rect.fromCenter(
              center: eyePos, width: eyeW * 0.5, height: eyeH * 0.5),
          Paint()..color = _ink);
      // sombra del párpado superior dentro del ojo
      canvas.drawOval(
          opening.translate(0, -eyeH * 0.42),
          Paint()..color = _ink.withValues(alpha: 0.22));
      // brillos
      canvas.drawCircle(
          eyePos.translate(-eyeW * 0.18, -eyeH * 0.22),
          eyeW * 0.19,
          Paint()..color = Colors.white.withValues(alpha: 0.95));
      canvas.drawCircle(
          eyePos.translate(eyeW * 0.17, eyeH * 0.17),
          eyeW * 0.09,
          Paint()..color = Colors.white.withValues(alpha: 0.65));

      // párpado al parpadear
      if (blink > 0.01) {
        final lidH = eyeH * blink;
        canvas.drawRect(
            Rect.fromLTWH(opening.left, opening.top, opening.width, lidH),
            Paint()..color = _skin);
        final lidY = opening.top + lidH;
        final lash = Path()
          ..moveTo(opening.left, lidY)
          ..quadraticBezierTo(
              center.dx, lidY + eyeH * 0.16, opening.right, lidY);
        canvas.drawPath(
            lash,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.012
              ..strokeCap = StrokeCap.round
              ..color = _ink);
      }
      canvas.restore();
    }

    // ── Nariz con fosas y volumen ────────────────────────────────────────
    final noseY = eyeY + s * 0.14;
    final noseW = s * 0.075, noseH = s * 0.05;
    final noseRect = Rect.fromCenter(
        center: Offset(cx, noseY), width: noseW, height: noseH);
    canvas.drawRRect(
        RRect.fromRectAndRadius(noseRect, Radius.circular(noseW * 0.45)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_skinShade, _ink.withValues(alpha: 0.85)],
          ).createShader(noseRect));
    // fosas nasales
    for (final sgn in [-1.0, 1.0]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + sgn * noseW * 0.24, noseY + noseH * 0.12),
              width: noseW * 0.22,
              height: noseH * 0.4),
          Paint()..color = _ink);
    }
    // brillo en la nariz
    canvas.drawCircle(
        Offset(cx - noseW * 0.18, noseY - noseH * 0.22),
        noseW * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.4));

    // ── Boquita con surco ────────────────────────────────────────────────
    final mouthY = noseY + noseH * 0.5 + s * 0.06;
    final mw = s * 0.085;
    if (mouthOpen > 0.05) {
      final h = s * 0.018 + mouthOpen * s * 0.085;
      final mRect = Rect.fromCenter(
          center: Offset(cx, mouthY + h * 0.1), width: mw * 1.7, height: h);
      final rr = RRect.fromRectAndRadius(mRect, Radius.circular(h * 0.5));
      canvas.drawRRect(rr, Paint()..color = _ink);
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx, mRect.bottom - h * 0.25),
                  width: mw * 1.2,
                  height: h * 0.55),
              Radius.circular(h * 0.4)),
          Paint()..color = _tongue);
      canvas.restore();
    } else {
      final lip = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.013
        ..strokeCap = StrokeCap.round
        ..color = _ink.withValues(alpha: 0.85);
      canvas.drawLine(Offset(cx, noseY + noseH * 0.5),
          Offset(cx, mouthY - s * 0.005), lip);
      final dip = s * 0.02 + smile * s * 0.024;
      final mouth = Path()
        ..moveTo(cx - mw, mouthY - s * 0.008)
        ..quadraticBezierTo(cx - mw * 0.5, mouthY + dip, cx, mouthY)
        ..quadraticBezierTo(
            cx + mw * 0.5, mouthY + dip, cx + mw, mouthY - s * 0.008);
      canvas.drawPath(mouth, lip);
    }
  }

  @override
  bool shouldRepaint(_ChimpPainter old) =>
      old.blink != blink ||
      old.mouthOpen != mouthOpen ||
      old.smile != smile ||
      old.lookX != lookX ||
      old.lookY != lookY ||
      old.excited != excited;
}
