import 'package:flutter/material.dart';
import 'package:kali_studio/auth/log_in.dart' show UpperLogo;
import 'package:kali_studio/screens/main_shell.dart';
import 'package:kali_studio/supabase/profile_manager.dart';
import 'package:kali_studio/supabase/studio_service.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudioSelectionScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const StudioSelectionScreen({super.key, this.onComplete});

  @override
  State<StudioSelectionScreen> createState() => _StudioSelectionScreenState();
}

class _StudioSelectionScreenState extends State<StudioSelectionScreen> {
  List<Studio> _studios = [];
  bool _loadingStudios = true;
  Studio? _selectedStudio;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSaving = false;

  List<Studio> get _filteredStudios {
    if (_searchQuery.isEmpty) return _studios;
    final q = _searchQuery.toLowerCase();
    return _studios.where((s) =>
      s.name.toLowerCase().contains(q) ||
      (s.address?.toLowerCase().contains(q) ?? false),
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadStudios();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  Future<void> _loadStudios() async {
    final studios = await StudioService.fetchStudios();
    if (mounted) setState(() { _studios = studios; _loadingStudios = false; });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_selectedStudio == null) return;

    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No session');

      await Supabase.instance.client.from('profiles').update({
        'institution_id': _selectedStudio!.id,
      }).eq('id', user.id);

      clearProfileCache();

      if (!mounted) return;
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos guardar tu elección. Intentá nuevamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final decorationColor = KaliColors.sand2;
    return Scaffold(
      backgroundColor: KaliColors.background,
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(200),
                    ),
                    color: decorationColor,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(200),
                    ),
                    color: decorationColor,
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const UpperLogo(),
                      const SizedBox(height: 20),
                      Text(
                        'Elegí tu estudio',
                        style: KaliText.loginDisplay(KaliColors.espresso),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seleccioná el estudio al que pertenecés.',
                        style: KaliText.body(KaliColors.clayDark, size: 14),
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: _loadingStudios
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  TextField(
                                    controller: _searchController,
                                    style: KaliText.body(KaliColors.espresso, size: 14),
                                    decoration: InputDecoration(
                                      hintText: 'Buscar gimnasio...',
                                      hintStyle: KaliText.body(KaliColors.clayDark, size: 14),
                                      prefixIcon: Icon(Icons.search_rounded, color: KaliColors.clayDark, size: 20),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(Icons.close_rounded, color: KaliColors.clayDark, size: 18),
                                              onPressed: () => _searchController.clear(),
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: KaliColors.sand,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: KaliColors.sand2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: KaliColors.sand2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: KaliColors.espresso, width: 1.5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: _filteredStudios.isEmpty
                                        ? Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: KaliColors.sand,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              _studios.isEmpty
                                                  ? 'No hay estudios disponibles por el momento.'
                                                  : 'No se encontraron resultados para "$_searchQuery".',
                                              style: KaliText.body(KaliColors.clayDark, size: 14),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: _filteredStudios.length,
                                            itemBuilder: (context, index) {
                                              final studio = _filteredStudios[index];
                                              final isSelected = _selectedStudio?.id == studio.id;
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 10),
                                                child: GestureDetector(
                                                  onTap: () => setState(() => _selectedStudio = studio),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 160),
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: isSelected ? KaliColors.espresso : KaliColors.sand,
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: isSelected ? KaliColors.espresso : KaliColors.sand2,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            color: isSelected ? KaliColors.clay : KaliColors.espresso,
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          child: Icon(Icons.fitness_center_rounded,
                                                              size: 18, color: KaliColors.warmWhite),
                                                        ),
                                                        const SizedBox(width: 14),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                studio.name,
                                                                style: KaliText.body(
                                                                  isSelected ? KaliColors.warmWhite : KaliColors.espresso,
                                                                  size: 14,
                                                                  weight: FontWeight.w600,
                                                                ),
                                                              ),
                                                              if (studio.address != null) ...[
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  studio.address!,
                                                                  style: KaliText.body(
                                                                    isSelected
                                                                        ? KaliColors.warmWhite.withValues(alpha: 0.7)
                                                                        : KaliColors.clayDark,
                                                                    size: 12,
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                        if (isSelected)
                                                          Icon(Icons.check_circle_rounded, color: KaliColors.clay, size: 20),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _selectedStudio == null || _isSaving ? null : _handleContinue,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isSaving 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 8,
                                children: [
                                  Text('Continuar', style: KaliText.buttonText(KaliColors.background)),
                                  const Icon(Icons.arrow_forward),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          try {
                            await Supabase.instance.client.auth.signOut();
                          } catch (_) {}
                        },
                        child: Text(
                          'Cerrar sesión',
                          style: KaliText.body(KaliColors.espresso, size: 14, weight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
