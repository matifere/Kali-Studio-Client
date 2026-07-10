import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../supabase/routine_service.dart';
import '../../theme/kali_theme.dart';
import '../../widgets/section_label.dart';
import '../../widgets/web_page_wrapper.dart';

/// Pestaña "Mi rutina": muestra la rutina de ejercicios que el estudio
/// le asignó al alumno, con la lista de ejercicios numerados.
class RutinaScreen extends StatefulWidget {
  const RutinaScreen({super.key});

  @override
  State<RutinaScreen> createState() => _RutinaScreenState();
}

class _RutinaScreenState extends State<RutinaScreen> {
  late Future<MyRoutine?> _routineFuture;

  @override
  void initState() {
    super.initState();
    _routineFuture = RoutineService.fetchMyRoutine();
  }

  Future<void> _refresh() async {
    setState(() {
      _routineFuture = RoutineService.fetchMyRoutine();
    });
    await _routineFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      body: SafeArea(
        bottom: false,
        child: WebPageWrapper(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: KaliColors.espresso,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: FutureBuilder<MyRoutine?>(
                      future: _routineFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child:
                                Center(child: CircularProgressIndicator()),
                          );
                        }

                        final routine = snapshot.data;
                        if (routine == null) return _buildEmptyState();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel('Tu rutina actual'),
                            const SizedBox(height: 2),
                            _buildRoutineCard(routine),
                            if (routine.exercises.isNotEmpty) ...[
                              const SizedBox(height: 36),
                              const SectionLabel('Ejercicios'),
                              const SizedBox(height: 2),
                              _buildExerciseList(routine.exercises),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
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
            top: -48,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KaliColors.espressoL.withValues(alpha: 0.55),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MI RUTINA',
                style: KaliText.label(KaliColors.clay)
                    .copyWith(fontSize: 10, letterSpacing: 1.8),
              ),
              const SizedBox(height: 8),
              Text(
                'La rutina de ejercicios que tu estudio preparó para vos.',
                style: KaliText.body(
                  KaliColors.warmWhite.withValues(alpha: 0.72),
                  size: 14,
                  weight: FontWeight.w400,
                ).copyWith(height: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_outlined,
                size: 48, color: KaliColors.clayDark.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Todavía no tenés una rutina asignada',
              style: KaliText.body(KaliColors.espresso,
                  size: 15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando tu instructor te asigne una, la vas a ver acá.',
              textAlign: TextAlign.center,
              style: KaliText.body(KaliColors.clayDark, size: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineCard(MyRoutine routine) {
    final assignedLabel = routine.assignedAt != null
        ? DateFormat("d 'de' MMMM yyyy", 'es').format(routine.assignedAt!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KaliColors.espresso,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            routine.name,
            style: KaliText.heading(KaliColors.warmWhite, size: 22),
          ),
          if (routine.description != null &&
              routine.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              routine.description!,
              style: KaliText.body(
                KaliColors.warmWhite.withValues(alpha: 0.72),
                size: 13,
              ).copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.fitness_center_outlined,
                  size: 14, color: KaliColors.clay),
              const SizedBox(width: 6),
              Text(
                '${routine.exercises.length} ejercicios',
                style: KaliText.body(KaliColors.clay,
                    size: 12, weight: FontWeight.w600),
              ),
              if (assignedLabel != null) ...[
                const SizedBox(width: 16),
                Icon(Icons.event_outlined, size: 14, color: KaliColors.clay),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Asignada el $assignedLabel',
                    style: KaliText.body(KaliColors.clay, size: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(List<String> exercises) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: KaliColors.sand,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          for (int i = 0; i < exercises.length; i++) ...[
            if (i > 0)
              Divider(color: KaliColors.sand2, thickness: 1, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: KaliColors.espresso,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: KaliText.body(KaliColors.warmWhite,
                            size: 12, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        exercises[i],
                        style: KaliText.body(KaliColors.espresso,
                            size: 14, weight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
