import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class GaleriaScreen extends StatefulWidget {
  final int eventoId;

  const GaleriaScreen({super.key, required this.eventoId});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  List fotos = [];

  Future<void> selecionarFoto() async {
    final arquivos = await FilePicker.pickFiles(type: FileType.image);

    if (arquivos.isEmpty) return;

    final arquivo = arquivos.first;

    final bytes = await arquivo.readAsBytes();

    final sucesso = await ApiService.uploadFoto(
      bytes: bytes,
      nomeArquivo: arquivo.name,
      eventoId: widget.eventoId,
    );

    if (sucesso) {
      await carregarFotos();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto enviada com sucesso')));
    }
  }

  @override
  void initState() {
    super.initState();
    carregarFotos();
  }

  Future<void> carregarFotos() async {
    try {
      final lista = await ApiService.buscarFotos(widget.eventoId);

      debugPrint('FOTOS RECEBIDAS: ${lista.length}');

      if (lista.isNotEmpty) {
        debugPrint('URL DA PRIMEIRA FOTO: ${lista.first['url_foto']}');
      }

      if (!mounted) return;

      setState(() {
        fotos = lista;
      });
    } catch (erro) {
      debugPrint('ERRO AO BUSCAR FOTOS: $erro');
    }
  }

  Future baixarFoto(String urlFoto) async {
    final uri = Uri.parse('https://momentz-production.up.railway.app$urlFoto');

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeria'),

        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: selecionarFoto,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: GridView.builder(
          itemCount: fotos.length,

          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),

          itemBuilder: (context, index) {
            final foto = fotos[index];

            final String? urlFoto = foto['url_foto'] as String?;

            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,

                  builder: (_) => Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        SizedBox(
                          height: 500,

                          child: InteractiveViewer(
                            child: Image.network(
                              urlFoto ?? '',
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image, size: 40),
                                );
                              },
                            ),
                          ),
                        ),

                        const Divider(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                          children: [
                            TextButton.icon(
                              onPressed: () {
                                baixarFoto(foto['url_foto']);
                              },

                              icon: const Icon(Icons.download),
                              label: const Text('Baixar'),
                            ),

                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },

                              icon: const Icon(Icons.close),
                              label: const Text('fechar'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },

              child: Card(
                clipBehavior: Clip.antiAlias,

                child: urlFoto != null && urlFoto.isNotEmpty
                    ? Image.network(
                        urlFoto,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 40),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported, size: 40),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
