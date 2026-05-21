import 'package:flutter/material.dart';
import 'package:kali_studio/auth/log_in.dart';
import 'package:kali_studio/supabase/studio_service.dart';
import 'package:kali_studio/supabase/supabase_auth_service.dart';
import 'package:kali_studio/theme/kali_text_field.dart';
import 'package:kali_studio/theme/kali_theme.dart';
import 'package:kali_studio/utils/auth_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = const SupabaseAuthService();
  bool _showPassword = false;
  bool _isLoading = false;

  int _step = 0;
  List<Studio> _studios = [];
  bool _loadingStudios = true;
  Studio? _selectedStudio;
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decorationColor = KaliColors.sand2;
    return Scaffold(
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
                  child: _step == 0 ? _buildStudioStep() : _buildFormStep(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
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
          if (_loadingStudios)
            const Center(child: CircularProgressIndicator())
          else ...[
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
            if (_filteredStudios.isEmpty)
              Container(
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
            else
              ...(_filteredStudios.map((studio) {
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
                            color: isSelected
                                ? KaliColors.clay
                                : KaliColors.espresso,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.fitness_center_rounded,
                              size: 18,
                              color: KaliColors.warmWhite),
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
                          Icon(Icons.check_circle_rounded,
                              color: KaliColors.clay, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            })),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _selectedStudio == null
                ? null
                : () => setState(() => _step = 1),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Text('Continuar',
                        style: KaliText.buttonText(KaliColors.background)),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          TextButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LogIn())),
            child: const Text('Iniciar Sesión'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _step = 0),
                icon: Icon(Icons.arrow_back_rounded, color: KaliColors.espresso),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: KaliColors.espresso,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _selectedStudio!.name,
                  style: KaliText.body(KaliColors.warmWhite,
                      size: 12, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Text(
            'Crear cuenta',
            textAlign: TextAlign.center,
            style: KaliText.loginDisplay(KaliColors.espresso),
          ),
          KaliTextField(
              label: 'NOMBRE COMPLETO',
              hint: 'Tu nombre completo',
              suffixIcon: Icons.person,
              controller: _fullNameController),
          KaliTextField(
              label: 'CORREO ELECTRONICO',
              hint: 'tumail@mail.com',
              suffixIcon: Icons.mail,
              controller: _emailController),
          KaliTextField(
            label: 'CONTRASEÑA',
            hint: '• • • • • • • •',
            obscureText: !_showPassword,
            controller: _passwordController,
            suffixIcon: _showPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            onSuffixTap: () => setState(() => _showPassword = !_showPassword),
          ),
          KaliTextField(
            label: 'CONFIRMAR CONTRASEÑA',
            hint: '• • • • • • • •',
            obscureText: !_showPassword,
            controller: _confirmPasswordController,
            suffixIcon: _showPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            onSuffixTap: () => setState(() => _showPassword = !_showPassword),
          ),
          FilledButton(
            onPressed: _isLoading ? null : _handleRegister,
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoading ? 'Creando cuenta...' : 'Registrarse',
                      style: KaliText.buttonText(KaliColors.background),
                    ),
                    if (!_isLoading) const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          TextButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LogIn())),
            child: const Text('Iniciar Sesión'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Completa todos los campos.');
      return;
    }

    if (password.length < 8) {
      _showMessage('La contraseña debe tener al menos 8 caracteres.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        fullName: fullName,
        email: email,
        password: password,
        studioId: _selectedStudio!.id,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(humanizeAuthError(error.message,
          fallback: 'No pudimos crear la cuenta. Intentá de nuevo.'));
    } catch (error) {
      if (!mounted) return;
      _showMessage(humanizeAuthError(error.toString(),
          fallback: 'No pudimos crear la cuenta. Intentá de nuevo.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
