import 'dart:typed_data';
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
  List<dynamic> fotos = [];

  bool carregando = true;
  bool enviando = false;

  @override
  void initState() {
    super.initState();
    carregarFotos();
  }

  Future<void> carregarFotos() async {
    if (mounted) {
      setState(() => carregando = true);
    }

    try {
      final lista = await ApiService.buscarFotosAdministrador(widget.eventoId);

      if (!mounted) return;

      setState(() {
        fotos = lista;
        carregando = false;
      });

      debugPrint('FOTOS RECEBIDAS: ${lista.length}');

      if (lista.isNotEmpty) {
        debugPrint('PRIMEIRA FOTO: ${lista.first['url_foto']}');
      }
    } catch (erro) {
      debugPrint('ERRO AO BUSCAR FOTOS: $erro');

      if (!mounted) return;

      setState(() => carregando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar galeria: $erro')),
      );
    }
  }

  Future<void> selecionarFotos() async {
    if (enviando) return;

    try {
      final arquivos = await FilePicker.pickFiles(type: FileType.image);

      if (arquivos.isEmpty) return;

      if (arquivos.length > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você pode enviar no máximo 20 fotos por vez.'),
          ),
        );
        return;
      }

      final List<Uint8List> arquivosBytes = [];
      final List<String> nomesArquivos = [];

      for (final arquivo in arquivos) {
        final bytes = await arquivo.readAsBytes();

        if (bytes.isEmpty) {
          throw Exception('Não foi possível ler ${arquivo.name}.');
        }

        arquivosBytes.add(bytes);
        nomesArquivos.add(arquivo.name);
      }

      if (!mounted) return;

      setState(() => enviando = true);

      final resposta = await ApiService.uploadFotosAdministrador(
        arquivosBytes: arquivosBytes,
        nomesArquivos: nomesArquivos,
        eventoId: widget.eventoId,
      );

      await carregarFotos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Fotos enviadas com sucesso!'),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar fotos: $erro')));
    } finally {
      if (mounted) {
        setState(() => enviando = false);
      }
    }
  }

  Future<void> baixarFoto(String urlFoto) async {
    try {
      final uri = Uri.tryParse(urlFoto);

      if (uri == null || !uri.hasScheme) {
        throw Exception('O endereço da foto não é uma URL válida.');
      }

      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!abriu) {
        throw Exception('Não foi possível abrir o endereço da foto.');
      }
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao abrir foto: $erro')));
    }
  }

  void visualizarFoto(Map<String, dynamic> foto) {
    final urlFoto = foto['url_foto']?.toString() ?? '';

    if (urlFoto.isEmpty) return;

    final nomeConvidado = foto['nome_convidado']?.toString();

    final enviadoPor = foto['convidado_id'] == null
        ? 'Administrador'
        : (nomeConvidado != null && nomeConvidado.isNotEmpty
              ? nomeConvidado
              : 'Convidado');

    showDialog(
      context: context,
      builder: (context) {
        final alturaTela = MediaQuery.of(context).size.height;

        return Dialog(
          child: SizedBox(
            width: 600,
            height: alturaTela * 0.78,
            child: Column(
              children: [
                // IMAGEM
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: InteractiveViewer(
                      child: Image.network(
                        urlFoto,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const Divider(height: 1),

                // INFORMAÇÕES DO REMETENTE
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.purple,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Foto enviada por',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              enviadoPor,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // BOTÕES
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => baixarFoto(urlFoto),
                        icon: const Icon(Icons.download),
                        label: const Text('Baixar'),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Fechar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeria'),
        actions: [
          IconButton(
            tooltip: 'Atualizar galeria',
            icon: const Icon(Icons.refresh),
            onPressed: carregarFotos,
          ),
          IconButton(
            tooltip: 'Adicionar fotos',
            icon: const Icon(Icons.add_a_photo),
            onPressed: enviando ? null : selecionarFotos,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: carregando
            ? const Center(child: CircularProgressIndicator())
            : fotos.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 65),
                    SizedBox(height: 12),
                    Text('Nenhuma foto encontrada.'),
                    SizedBox(height: 8),
                    Text('Adicione fotos para começar sua galeria.'),
                  ],
                ),
              )
            : GridView.builder(
                itemCount: fotos.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final foto = Map<String, dynamic>.from(fotos[index]);
                  final urlFoto = foto['url_foto']?.toString() ?? '';

                  return GestureDetector(
                    onTap: () => visualizarFoto(foto),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: urlFoto.isNotEmpty
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
      floatingActionButton: enviando
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(),
            )
          : FloatingActionButton.extended(
              onPressed: selecionarFotos,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Adicionar fotos'),
            ),
    );
  }
}
