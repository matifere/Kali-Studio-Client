import 'package:flutter/material.dart';
import 'package:kali_studio/models/models.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/google_fonts_helper.dart';

class ClassListItem extends StatelessWidget {
  final PilatesClass cls;
  final VoidCallback onTap;

  const ClassListItem({super.key, required this.cls, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Hora
            SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(cls.time,
                      style:
                          GoogleFontsHelper.cormorant(KaliColors.espresso, 16)),
                  Text(cls.period, style: KaliText.label(KaliColors.clay)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Barra lateral
            Container(
              width: 2,
              height: 36,
              decoration: BoxDecoration(
                color: cls.isBooked ? KaliColors.clay : KaliColors.sageLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cls.name,
                      style: KaliText.body(KaliColors.espresso, size: 13)),
                  const SizedBox(height: 2),
                  Text('${cls.instructor} · ${cls.room}',
                      style: KaliText.caption(KaliColors.clayDark)),
                ],
              ),
            ),
            // Badge
            if (cls.isBooked)
              _BookedBadge()
            else
              Text(
                '${cls.availableSpots} ${cls.availableSpots == 1 ? "lugar" : "lugares"}',
                style: KaliText.caption(KaliColors.sage),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: KaliColors.sageLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('Reservado',
          style: KaliText.caption(KaliColors.sage)
              .copyWith(fontWeight: FontWeight.w500, fontSize: 10)),
    );
  }
}
