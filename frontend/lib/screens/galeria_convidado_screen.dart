import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/api_service.dart';

class GaleriaConvidadoScreen extends StatefulWidget {
  const GaleriaConvidadoScreen({super.key});

  @override
  State<GaleriaConvidadoScreen> createState() => _GaleriaConvidadoScreenState();
}

class _GaleriaConvidadoScreenState extends State<GaleriaConvidadoScreen> {
  static const Color roxoEscuro = Color(0xFF210020);
  static const Color roxo = Color(0xFF50004F);
  static const Color magenta = Color(0xFFE000B8);

  List<dynamic> fotos = [];

  bool carregando = true;
  bool enviando = false;

  @override
  void initState() {
    super.initState();
    carregarFotos();
  }

  // ============================================================
  // CARREGAR FOTOS DO CONVIDADO
  // ============================================================

  Future<void> carregarFotos() async {
    if (mounted) {
      setState(() => carregando = true);
    }

    try {
      final lista = await ApiService.buscarMinhasFotosConvidado();

      if (!mounted) return;

      setState(() {
        fotos = lista;
        carregando = false;
      });

      debugPrint('FOTOS DO CONVIDADO: ${lista.length}');

      if (lista.isNotEmpty) {
        debugPrint('PRIMEIRA FOTO: ${lista.first['url_foto']}');
      }
    } catch (erro) {
      debugPrint('ERRO AO BUSCAR FOTOS: $erro');

      if (!mounted) return;

      setState(() => carregando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar suas fotos: $erro')),
      );
    }
  }

  // ============================================================
  // SELECIONAR E ENVIAR FOTOS
  // ============================================================

  Future<void> selecionarFotos() async {
    if (enviando) return;

    try {
      final arquivos = await FilePicker.pickFiles(type: FileType.image);

      if (arquivos.isEmpty) return;

      if (arquivos.length > 5) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você pode enviar no máximo 5 fotos por vez.'),
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

      final resposta = await ApiService.uploadFotosConvidado(
        arquivosBytes: arquivosBytes,
        nomesArquivos: nomesArquivos,
      );

      await carregarFotos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resposta['mensagem'] ?? 'Fotos enviadas com sucesso!'),
        ),
      );
    } catch (erro) {
      debugPrint('ERRO AO ENVIAR FOTOS: $erro');

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

  // ============================================================
  // VISUALIZAR FOTO AMPLIADA
  // ============================================================

  void visualizarFoto(String urlFoto) {
    if (urlFoto.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: roxoEscuro,
        child: Stack(
          children: [
            SizedBox(
              height: 500,
              child: InteractiveViewer(
                child: Image.network(
                  urlFoto,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              right: 5,
              top: 5,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARTÃO DA FOTO
  // ============================================================

  Widget _cartaoFoto(Map<String, dynamic> foto) {
    final urlFoto = foto['url_foto']?.toString() ?? '';

    return GestureDetector(
      onTap: () => visualizarFoto(urlFoto),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: const Color(0xFF241D29),
        child: urlFoto.isNotEmpty
            ? Image.network(
                urlFoto,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;

                  return const Center(
                    child: CircularProgressIndicator(color: magenta),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                },
              )
            : const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.white,
                  size: 40,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoEscuro,

      appBar: AppBar(
        backgroundColor: roxoEscuro,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Minha galeria'),
        actions: [
          IconButton(
            tooltip: 'Atualizar galeria',
            icon: const Icon(Icons.refresh),
            onPressed: carregando ? null : carregarFotos,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),

        child: carregando
            ? const Center(child: CircularProgressIndicator(color: magenta))
            : fotos.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 65,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Sua galeria está vazia.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Adicione fotos para guardar os momentos do evento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final largura = constraints.maxWidth;

                  final colunas = largura >= 1000
                      ? 4
                      : largura >= 600
                      ? 3
                      : 2;

                  return GridView.builder(
                    itemCount: fotos.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colunas,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final foto = Map<String, dynamic>.from(fotos[index]);

                      return _cartaoFoto(foto);
                    },
                  );
                },
              ),
      ),

      floatingActionButton: enviando
          ? const FloatingActionButton(
              onPressed: null,
              backgroundColor: roxo,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: selecionarFotos,
              backgroundColor: roxo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Adicionar fotos'),
            ),
    );
  }
}
