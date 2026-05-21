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
    final activeBackground = KaliColors.espresso;
    final activeDayText = KaliColors.background;
    final activeNumberText = KaliColors.background;

    return Row(
      children: List.generate(6, (i) {
        final isActive = i == widget.selectedIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 5 ? 6 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? activeBackground : KaliColors.sand2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(days[i],
                    style: KaliText.label(
                        isActive ? activeDayText : KaliColors.clayDark)),
                const SizedBox(height: 4),
                Text(nums[i],
                    style: GoogleFontsHelper.cormorant(
                        isActive ? activeNumberText : KaliColors.espresso, 17)),
                if (hasClass[i] && !isActive) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
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
