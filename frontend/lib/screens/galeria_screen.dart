import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

FilePickerResult? teste;

class GaleriaScreen extends StatefulWidget {
  final int eventoId;

  const GaleriaScreen({super.key, required this.eventoId});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  List fotos = [];

  Future selecionarFoto() async {
    FilePickerResult? resultado = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (resultado == null) return;

    final arquivo = resultado.files.first;

    final sucesso = await ApiService.uploadFoto(
      bytes: arquivo.bytes!,
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

  Future carregarFotos() async {
    final lista = await ApiService.buscarFotos(widget.eventoId);

    setState(() {
      fotos = lista;
    });
  }

  Future baixarFoto(String urlFoto) async {
    final uri = Uri.parse('http://localhost:3000$urlFoto');

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
                              'http://localhost:3000${foto['url_foto']}',
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

                child: Image.network(
                  'http://localhost:3000${foto['url_foto']}',
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
