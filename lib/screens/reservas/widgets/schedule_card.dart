import 'package:flutter/material.dart';
import '../../../../models/models.dart';
import '../../../../theme/kali_theme.dart';
import '../../../../utils/time_utils.dart';
import '../../../../widgets/google_fonts_helper.dart';
import 'hover_pill.dart';

class ScheduleCard extends StatelessWidget {
  final PilatesClass cls;
  final ClassCardAction action;
  final VoidCallback? onTap;

  const ScheduleCard({
    super.key,
    required this.cls,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = KaliColors.sand;
    final primaryText = KaliColors.espresso;
    final secondaryText = KaliColors.clayDark;
    final dotColor = KaliColors.clayDark.withValues(alpha: 0.72);

    final Widget button = switch (action) {
      ClassCardAction.booked => Text(
          'Reservada',
          style: KaliText.label(KaliColors.espresso)
              .copyWith(fontSize: 9, letterSpacing: 1.2),
        ),
      ClassCardAction.leaveWaitlist => HoverPill(
          label: 'En espera',
          icon: Icons.hourglass_top_rounded,
          background: KaliColors.clayDark,
          foreground: KaliColors.warmWhite,
          onTap: onTap,
        ),
      ClassCardAction.joinWaitlist => HoverPill(
          label: 'Anotarme',
          icon: Icons.add_rounded,
          background: KaliColors.sand2,
          foreground: KaliColors.espresso,
          onTap: onTap,
        ),
      ClassCardAction.book => HoverPill(
          label: 'Reservar',
          background: KaliColors.espresso,
          foreground: KaliColors.background,
          onTap: onTap,
        ),
    };

    // La tarjeta solo se atenúa si está llena y el usuario no participa:
    // si ya está en la lista de espera, su estado debe verse activo.
    final dimmed = action == ClassCardAction.joinWaitlist;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: action == ClassCardAction.leaveWaitlist
            ? Border.all(color: KaliColors.clayDark.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Opacity(
              opacity: dimmed ? 0.58 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        TimeUtils.formatTime12h(cls.time),
                        maxLines: 1,
                        style: KaliText.body(
                          primaryText,
                          size: 13,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${cls.durationMin} min',
                        style: KaliText.label(secondaryText)
                            .copyWith(fontSize: 9, letterSpacing: 1.1),
                      ),
                      if (action == ClassCardAction.joinWaitlist ||
                          action == ClassCardAction.leaveWaitlist) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: KaliColors.clayDark.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Completa',
                            style: KaliText.label(secondaryText)
                                .copyWith(fontSize: 8, letterSpacing: 1.1),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cls.name,
                    style: GoogleFontsHelper.cormorant(
                      primaryText,
                      22,
                      italic: true,
                      weight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          cls.instructor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KaliText.body(
                            secondaryText,
                            size: 12,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          button,
        ],
      ),
    );
  }
}
