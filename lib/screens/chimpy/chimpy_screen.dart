import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/kali_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/google_fonts_helper.dart';
import '../../widgets/web_page_wrapper.dart';
import '../../widgets/chimp_avatar.dart';

/// Pantalla del amigo virtual "Chimpy" 🐒
///
/// Diseño + interacción local (sin backend ni IA): el chimpancé está dibujado
/// con [ChimpAvatar] (parpadea, mira, sonríe, habla y rebota), el input
/// funciona y Chimpy responde con frases enlatadas según palabras clave,
/// mostrando un indicador de "escribiendo…".
class ChimpyScreen extends StatefulWidget {
  const ChimpyScreen({super.key});

  @override
  State<ChimpyScreen> createState() => _ChimpyScreenState();
}

class _ChimpyScreenState extends State<ChimpyScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _rng = math.Random();

  final List<_Message> _messages = [
    _Message('¡Uh uh ah ah! 🐒 Soy Chimpy, tu compañero del estudio.',
        fromChimpy: true),
    _Message('Tocame la carita o escribime — ¿en qué te ayudo hoy?',
        fromChimpy: true),
  ];

  bool _typing = false;
  ChimpMood _mood = ChimpMood.happy;
  bool _talking = false;
  int _react = 0;

  static const List<String> _quickReplies = [
    'Mi próxima clase',
    'Tip de respiración',
    'Motivame ✨',
    'Mi plan',
    'Contame un chiste',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Lógica de conversación (local) ──────────────────────────────────────

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty || _typing) return;
    setState(() {
      _messages.add(_Message(text, fromChimpy: false));
      _input.clear();
      _typing = true;
      _mood = ChimpMood.thinking;
      _react++;
    });
    _scrollToEnd();

    Future.delayed(Duration(milliseconds: 700 + _rng.nextInt(700)), () {
      if (!mounted) return;
      final reply = _replyFor(text);
      setState(() {
        _typing = false;
        _messages.add(_Message(reply, fromChimpy: true));
        _mood = ChimpMood.happy;
        _talking = true;
        _react++;
      });
      _scrollToEnd();
      // Deja de "hablar" cuando termina la frase.
      Future.delayed(
          Duration(milliseconds: 900 + reply.length * 26), () {
        if (mounted) setState(() => _talking = false);
      });
    });
  }

  void _tapChimp() {
    if (_typing) return;
    const reactions = [
      '¡Jiji! Me hiciste cosquillas 🤭',
      '¡Uh uh ah ah! 🐒🍌',
      '¿Jugamos? ¡Tengo energía de mono!',
      'Me caés genial, humana 💛',
    ];
    setState(() {
      _mood = ChimpMood.excited;
      _react++;
      _talking = true;
      _messages.add(_Message(reactions[_rng.nextInt(reactions.length)],
          fromChimpy: true));
    });
    _scrollToEnd();
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _talking = false;
        _mood = ChimpMood.happy;
      });
    });
  }

  String _replyFor(String input) {
    final t = input.toLowerCase();
    if (t.contains('clase') || t.contains('reserv')) {
      return 'Tu próxima clase es Reformer hoy a las 18:00 💪 ¡Te espero ahí!';
    }
    if (t.contains('plan')) {
      return 'Tu plan sigue activo unos días más. ¿Querés que te recuerde renovarlo? 📅';
    }
    if (t.contains('respir')) {
      return 'Inhalá 4 segundos por la nariz, sostené 4, exhalá 6 por la boca. '
          'Repetí 5 veces 🌬️ ¡Se siente increíble!';
    }
    if (t.contains('motiv')) {
      return 'Cada clase es una banana más cerca de tu mejor versión 🍌✨ '
          '¡Vamos que podés!';
    }
    if (t.contains('chiste') || t.contains('chist')) {
      return '¿Qué hace un mono con una metralleta? 🐒 ¡Bananas de fuego! 🍌🔥';
    }
    if (t.contains('hola') || t.contains('buenas')) {
      return '¡Hola hola! 🐒 ¿Lista para moverte hoy?';
    }
    if (t.contains('gracias')) {
      return '¡De nada! Para eso están los amigos monos 💛';
    }
    const generic = [
      '¡Uh uh ah ah! Contame más 🐒',
      'Me encanta charlar con vos. ¿Querés un tip para tu clase?',
      '🍌 Anotado. ¿En qué más te doy una mano?',
      '¡Buenísimo! Acá estoy para acompañarte.',
    ];
    return generic[_rng.nextInt(generic.length)];
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      body: SafeArea(
        bottom: false,
        child: WebPageWrapper(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  itemCount: _messages.length + (_typing ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_typing && i == _messages.length) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _TypingBubble(),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildBubble(_messages[i]),
                    );
                  },
                ),
              ),
              _buildQuickReplies(),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header con chimpancé ────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: KaliColors.espresso,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -44,
            child: _decorativeCircle(140, alpha: 0.16),
          ),
          Row(
            children: [
              ChimpAvatar(
                size: 64,
                mood: _mood,
                talking: _talking,
                reactTrigger: _react,
                onTap: _tapChimp,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chimpy',
                      style: GoogleFontsHelper.cormorant(
                          KaliColors.warmWhite, 30, weight: FontWeight.w400),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: KaliColors.sage,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _typing
                              ? 'escribiendo…'
                              : 'Tu amigo virtual · En línea',
                          style: KaliText.body(
                              KaliColors.warmWhite.withValues(alpha: 0.7),
                              size: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Burbujas ─────────────────────────────────────────────────────────────

  Widget _buildBubble(_Message m) {
    final isChimpy = m.fromChimpy;
    final bg = isChimpy ? KaliColors.sand : KaliColors.espresso;
    final fg = isChimpy ? KaliColors.espresso : KaliColors.warmWhite;

    return Row(
      mainAxisAlignment:
          isChimpy ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        Flexible(
          child: FadeSlideIn(
            offsetY: 8,
            duration: const Duration(milliseconds: 280),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isChimpy ? 4 : 20),
                  bottomRight: Radius.circular(isChimpy ? 20 : 4),
                ),
              ),
              child: Text(
                m.text,
                style: KaliText.body(fg, size: 14).copyWith(height: 1.45),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sugerencias rápidas ──────────────────────────────────────────────────

  Widget _buildQuickReplies() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return Pressable(
            onTap: () => _send(_quickReplies[i]),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: KaliColors.warmWhite,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: KaliColors.sand2, width: 1),
              ),
              child: Text(
                _quickReplies[i],
                style: KaliText.body(KaliColors.clayDark,
                    size: 13, weight: FontWeight.w500),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Barra de entrada (funcional, local) ──────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: KaliColors.warmWhite,
        border: Border(
          top: BorderSide(color: KaliColors.sand2, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: KaliColors.sand,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  style: KaliText.body(KaliColors.espresso, size: 14),
                  cursorColor: KaliColors.espresso,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Escribile a Chimpy…',
                    hintStyle: KaliText.body(
                        KaliColors.clayDark.withValues(alpha: 0.7),
                        size: 14),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Pressable(
              onTap: () => _send(_input.text),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: KaliColors.espresso,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_upward_rounded,
                    color: KaliColors.warmWhite, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorativeCircle(double size, {required double alpha}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KaliColors.espressoL.withValues(alpha: alpha),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool fromChimpy;
  _Message(this.text, {required this.fromChimpy});
}

/// Burbuja con tres puntitos animados mientras Chimpy "piensa".
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: KaliColors.sand,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_ctrl.value - i * 0.18) % 1.0;
                final t = (math.sin(phase * math.pi * 2) + 1) / 2;
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  child: Transform.translate(
                    offset: Offset(0, -3 * t),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: KaliColors.clayDark
                            .withValues(alpha: 0.4 + 0.5 * t),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
