import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/models.dart';
import '../../../../theme/kali_theme.dart';
import '../../../../utils/time_utils.dart';
import '../../../../widgets/google_fonts_helper.dart';
import 'book_confirm_button.dart';

class BookConfirmSheet extends StatelessWidget {
  final PilatesClass cls;
  final int cancellationHours;

  const BookConfirmSheet({
    super.key,
    required this.cls,
    this.cancellationHours = 2,
  });

  String get _hoursText =>
      cancellationHours == 1 ? '1 hora' : '$cancellationHours horas';

  @override
  Widget build(BuildContext context) {
    final primaryText = KaliColors.espresso;
    final mutedText = KaliColors.clayDark;

    final dateStr = cls.sessionDate != null
        ? DateFormat("EEEE d 'de' MMMM", 'es').format(cls.sessionDate!)
        : '';

    return Container(
      decoration: BoxDecoration(
        color: KaliColors.warmWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: KaliColors.sand2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Confirmar reserva',
            style: GoogleFontsHelper.cormorant(
              primaryText,
              30,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cls.name,
            style: KaliText.body(
              mutedText,
              size: 14,
              weight: FontWeight.w500,
            ),
          ),
          if (dateStr.isNotEmpty || cls.time.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (dateStr.isNotEmpty)
                  dateStr[0].toUpperCase() + dateStr.substring(1),
                if (cls.time.isNotEmpty) TimeUtils.formatTime12h(cls.time),
              ].join(' · '),
              style: KaliText.body(
                mutedText,
                size: 13,
                weight: FontWeight.w400,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KaliColors.sand,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: KaliColors.clay.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: KaliColors.clay),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cancellationHours <= 0
                        ? 'Podés cancelar tu reserva hasta el inicio de la clase. Si no asistís sin cancelar, se descontará una sesión de tu plan mensual.'
                        : 'Solo podés cancelar hasta $_hoursText antes de la clase. Pasado ese límite, se descontará una sesión de tu plan mensual.',
                    style: KaliText.body(
                      primaryText,
                      size: 13,
                      weight: FontWeight.w400,
                    ).copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BookConfirmButton(
            label: 'Confirmar reserva',
            filled: true,
            onTap: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 12),
          BookConfirmButton(
            label: 'Cancelar',
            filled: false,
            onTap: () => Navigator.pop(context, false),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
