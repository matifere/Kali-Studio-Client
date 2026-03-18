import 'package:flutter/material.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/widgets/google_fonts_helper.dart';

class WeekStrip extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDaySelected;

  const WeekStrip({
    super.key,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  static const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  static const nums = ['16', '17', '18', '19', '20', '21'];
  static const hasClass = [false, true, true, true, false, true];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (i) {
        final isActive = i == widget.selectedIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 5 ? 6 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? KaliColors.espresso : KaliColors.sand2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(days[i],
                    style: KaliText.label(
                        isActive ? KaliColors.clay : KaliColors.clayDark)),
                const SizedBox(height: 4),
                Text(nums[i],
                    style: GoogleFontsHelper.cormorant(
                        isActive ? KaliColors.warmWhite : KaliColors.espresso,
                        17)),
                if (hasClass[i] && !isActive) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: KaliColors.clay,
                      shape: BoxShape.circle,
                    ),
                  ),
                ] else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }),
    );
  }
}
