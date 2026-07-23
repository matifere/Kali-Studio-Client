import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import '../../supabase/studio_service.dart';
import '../../theme/kali_theme.dart';

class ConsentimientoScreen extends StatefulWidget {
  const ConsentimientoScreen({super.key});

  @override
  State<ConsentimientoScreen> createState() => _ConsentimientoScreenState();
}

class _ConsentimientoScreenState extends State<ConsentimientoScreen> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(document: _loadDocument());
  }

  Future<PdfDocument> _loadDocument() async {
    // Si la institución cargó su propio consentimiento, se muestra ese.
    // Si no (o si falla la descarga), se usa el PDF embebido en la app.
    try {
      final studio = await StudioService.fetchCurrentInstitution();
      final url = studio?.consentPdfUrl;
      if (url != null && url.isNotEmpty) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return PdfDocument.openData(response.bodyBytes);
        }
      }
    } catch (_) {
      // error no crítico: se ignora
    }
    return PdfDocument.openAsset('assets/docs/consentimiento.pdf');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_rounded,
                          color: KaliColors.espresso, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Consentimiento',
                    style: KaliText.loginDisplay(KaliColors.espresso)
                        .copyWith(fontSize: 22, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            Divider(color: KaliColors.sand2, thickness: 1, height: 1),
            Expanded(
              child: PdfViewPinch(
                controller: _controller,
                builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                  documentLoaderBuilder: (_) => const Center(
                      child: CircularProgressIndicator()),
                  pageLoaderBuilder: (_) => const Center(
                      child: CircularProgressIndicator()),
                  errorBuilder: (_, error) => Center(
                    child: Text('Error al cargar el documento',
                        style: KaliText.body(KaliColors.clayDark)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
