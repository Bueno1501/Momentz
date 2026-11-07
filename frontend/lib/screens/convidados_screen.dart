import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/page_container.dart';
import 'package:flutter/services.dart';

class ConvidadosScreen extends StatefulWidget {
  final int eventoId;

  const ConvidadosScreen({super.key, required this.eventoId});

  @override
  State<ConvidadosScreen> createState() => _ConvidadosScreenState();
}

class _ConvidadosScreenState extends State<ConvidadosScreen> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final buscaController = TextEditingController();

  bool mostrarFormulario = false;

  List convidados = [];

  PlatformFile? conviteSelecionado;
  Uint8List? conviteBytes;

  // ============================================================
  // ESTATÍSTICAS DOS CONVIDADOS CONFIRMADOS
  // ============================================================

  List get convidadosConfirmados {
    return convidados.where((convidado) {
      final status = (convidado['status_confirmacao'] ?? '')
          .toString()
          .toUpperCase();

      return status == 'CONFIRMADO';
    }).toList();
  }

  int quantidade(String campo, dynamic convidado) {
    return int.tryParse((convidado[campo] ?? 0).toString()) ?? 0;
  }

  int get totalBebes {
    return convidadosConfirmados.fold(
      0,
      (total, convidado) => total + quantidade('criancas_0_3', convidado),
    );
  }

  int get totalCriancas {
    return convidadosConfirmados.fold(
      0,
      (total, convidado) => total + quantidade('criancas_4_7', convidado),
    );
  }

  int get totalAdultos {
    return convidadosConfirmados.fold(
      0,
      (total, convidado) =>
          total + 1 + quantidade('acompanhantes_8_mais', convidado),
    );
  }

  int get totalPessoasConfirmadas {
    return totalBebes + totalCriancas + totalAdultos;
  }

  int get quantidadeConvidadosConfirmados {
    return convidadosConfirmados.length;
  }

  int get quantidadePendentes {
    return convidados.where((convidado) {
      return (convidado['status_confirmacao'] ?? '').toString().toUpperCase() ==
          'PENDENTE';
    }).length;
  }

  int get quantidadeRecusados {
    return convidados.where((convidado) {
      return (convidado['status_confirmacao'] ?? '').toString().toUpperCase() ==
          'RECUSADO';
    }).length;
  }

  // ============================================================
  // ATUALIZAR STATUS
  // ============================================================

  Future atualizarStatus(int convidadoId, String status) async {
    await ApiService.alterarStatusConvidado(
      convidadoId: convidadoId,
      status: status,
    );

    await carregarConvidados();
  }

  // ============================================================
  // CARREGAR CONVIDADOS
  // ============================================================

  Future carregarConvidados() async {
    final lista = await ApiService.buscarConvidados(widget.eventoId);

    if (!mounted) return;

    setState(() {
      convidados = lista;
    });
  }

  // ============================================================
  // IMPORTAR CONVITE
  // ============================================================

  Future<void> importarConvite() async {
    final arquivos = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (arquivos.isEmpty) {
      return;
    }

    final arquivo = arquivos.first;
    final bytes = await arquivo.readAsBytes();

    if (!mounted) return;

    setState(() {
      conviteSelecionado = arquivo;
      conviteBytes = bytes;
    });

    try {
      final resposta = await ApiService.uploadConvite(
        bytes: bytes,
        nomeArquivo: arquivo.name,
        eventoId: widget.eventoId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resposta.containsKey('convite_url')
                ? 'Convite salvo no evento com sucesso!'
                : resposta['erro'] ?? 'Erro ao salvar o convite',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar o convite ao servidor.'),
        ),
      );
    }
  }

  // ============================================================
  // GERAR LINK DO EVENTO
  // ============================================================

  Future<void> gerarLinkEvento() async {
    try {
      final evento = await ApiService.buscarEventoPorId(widget.eventoId);

      debugPrint('Evento recebido pelo Flutter: $evento');
      debugPrint('ID do evento aberto: ${widget.eventoId}');

      final token = evento['token_convite'];

      debugPrint('Token recebido pelo Flutter: $token');

      if (token == null || token.toString().isEmpty) {
        throw Exception('Token do convite não encontrado');
      }

      final link = Uri.base.resolve('/convite/$token').toString();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Link do evento'),
          content: SelectableText(link),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));

                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(const SnackBar(content: Text('Link copiado!')));
              },
              child: const Text('Copiar link'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar link: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    carregarConvidados();
  }

  // ============================================================
  // ADICIONAR CONVIDADO
  // ============================================================

  Future adicionarConvidado() async {
    if (nomeController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));

      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (!emailRegex.hasMatch(emailController.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um email válido.')));

      return;
    }

    final resposta = await ApiService.cadastrarConvidado(
      nome: nomeController.text,
      email: emailController.text,
      eventoId: widget.eventoId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resposta['mensagem'])));

    nomeController.clear();
    emailController.clear();

    setState(() {
      mostrarFormulario = false;
    });

    await carregarConvidados();
  }

  // ============================================================
  // REMOVER CONVIDADO
  // ============================================================

  Future removerConvidado(int convidadoId) async {
    await ApiService.excluirConvidado(convidadoId);

    await carregarConvidados();
  }

  // ============================================================
  // VISUALIZAR DETALHES
  // ============================================================

  void visualizarDetalhes(dynamic convidado) {
    String valor(String campo) {
      final dado = convidado[campo];
      if (dado == null || dado.toString().trim().isEmpty) {
        return 'Não informado';
      }
      return dado.toString();
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.person, color: Colors.deepPurple),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  valor('nome'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detalheConvidado(Icons.email, 'E-mail', valor('email')),
                _detalheConvidado(Icons.phone, 'Telefone', valor('telefone')),
                _detalheConvidado(
                  Icons.event_available,
                  'Confirmação',
                  valor('status_confirmacao'),
                ),
                const Divider(height: 28),
                const Text(
                  'Acompanhantes e crianças',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _detalheConvidado(
                  Icons.child_care,
                  'Crianças de 0 a 3 anos',
                  valor('criancas_0_3'),
                ),
                _detalheConvidado(
                  Icons.child_friendly,
                  'Crianças de 4 a 7 anos',
                  valor('criancas_4_7'),
                ),
                _detalheConvidado(
                  Icons.people,
                  'Acompanhantes de 8 anos ou mais',
                  valor('acompanhantes_8_mais'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DETALHES DO CONVIDADO
  // ============================================================

  Widget _detalheConvidado(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Colors.deepPurple, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 3),
                Text(valor, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALCULAR TOTAL DE PESSOAS POR CONVIDADO
  // ============================================================

  int calcularTotalPessoas(dynamic convidado) {
    int quantidade(String campo) {
      return int.tryParse((convidado[campo] ?? 0).toString()) ?? 0;
    }

    return 1 +
        quantidade('criancas_0_3') +
        quantidade('criancas_4_7') +
        quantidade('acompanhantes_8_mais');
  }

  // ============================================================
  // CARD COMPACTO DE ESTATÍSTICA
  // ============================================================

  Widget cardEstatistica({
    required String titulo,
    required int valor,
    required IconData icone,
  }) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8E9FB),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: const Color(0xFF7A2795), size: 18),
            const SizedBox(height: 3),
            Text(
              valor.toString(),
              style: const TextStyle(
                color: Color(0xFF54206D),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF54206D),
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAINEL DE ESTATÍSTICAS
  // ============================================================

  Widget painelEstatisticas() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_rounded, color: Color(0xFF7A2795), size: 16),
              SizedBox(width: 5),
              Text(
                'Quantidade de Convidados',
                style: TextStyle(
                  color: Color(0xFF4A176B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              cardEstatistica(
                titulo: 'Total',
                valor: totalPessoasConfirmadas,
                icone: Icons.groups_rounded,
              ),
              const SizedBox(width: 5),
              cardEstatistica(
                titulo: 'Bebês',
                valor: totalBebes,
                icone: Icons.child_care_rounded,
              ),
              const SizedBox(width: 5),
              cardEstatistica(
                titulo: 'Crianças',
                valor: totalCriancas,
                icone: Icons.child_friendly_rounded,
              ),
              const SizedBox(width: 5),
              cardEstatistica(
                titulo: 'Adultos',
                valor: totalAdultos,
                icone: Icons.people_alt_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAMPO DE PESQUISA
  // ============================================================

  Widget campoPesquisa() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: buscaController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 10, color: Color(0xFF40234D)),
        decoration: InputDecoration(
          hintText: 'Buscar convidado...',
          hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: Color(0xFF7A2795),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    buscaController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final termoBusca = buscaController.text.trim().toLowerCase();

    final convidadosFiltrados = convidados.where((convidado) {
      final nome = (convidado['nome'] ?? '').toString().toLowerCase();
      final email = (convidado['email'] ?? '').toString().toLowerCase();

      return nome.contains(termoBusca) || email.contains(termoBusca);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF21002E),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fundo_convidados.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF260033).withValues(alpha: 0.48),
            ),
          ),
          SafeArea(
            child: PageContainer(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // CABEÇALHO SUPERIOR MOMENTZ
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEC00C8), Color(0xFF8E0AAE)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(9),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.photo_camera_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'MOMENTZ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: importarConvite,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 25,
                              minHeight: 25,
                            ),
                            tooltip: 'Imagem do convite',
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // TÍTULO E DESCRIÇÃO
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 9, 9),
                      decoration: const BoxDecoration(
                        color: Color(0xFF351044),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(9),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEC00C8,
                              ).withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFF7BEA),
                                width: 0.7,
                              ),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Convidados',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Gerencie os convidados do seu evento',
                                  style: TextStyle(
                                    color: Color(0xFFE8CDEB),
                                    fontSize: 7.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (conviteSelecionado != null)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF65E69A),
                              size: 15,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ESTATÍSTICAS: TOTAL, BEBÊS, CRIANÇAS E ADULTOS
                    painelEstatisticas(),

                    const SizedBox(height: 8),

                    // BOTÕES DE AÇÃO
                    Row(
                      children: [
                        Expanded(
                          child: _botaoAcao(
                            texto: mostrarFormulario
                                ? 'Fechar formulário'
                                : 'Adicionar Convidado',
                            icone: mostrarFormulario
                                ? Icons.close
                                : Icons.person_add_alt_1,
                            onPressed: () {
                              setState(() {
                                mostrarFormulario = !mostrarFormulario;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _botaoAcao(
                            texto: 'Gerar Link',
                            icone: Icons.link,
                            onPressed: gerarLinkEvento,
                          ),
                        ),
                      ],
                    ),

                    // FORMULÁRIO EXPANSÍVEL
                    if (mostrarFormulario) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Novo convidado',
                              style: TextStyle(
                                color: Color(0xFF4A176B),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: nomeController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Nome do convidado',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'E-mail do convidado',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: adicionarConvidado,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD900C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  'Adicionar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // CONVITE IMPORTADO, QUANDO EXISTIR
                    if (conviteSelecionado != null) ...[
                      Container(
                        padding: const EdgeInsets.all(9),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Imagem do Convite',
                              style: TextStyle(
                                color: Color(0xFF4A176B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 7),
                            if (['jpg', 'jpeg', 'png'].contains(
                              conviteSelecionado!.extension?.toLowerCase(),
                            ))
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  conviteBytes!,
                                  height: 180,
                                  fit: BoxFit.contain,
                                ),
                              )
                            else
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    color: Color(0xFF7A2795),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Arquivo PDF selecionado',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],

                    // LISTA E PESQUISA
                    Row(
                      children: [
                        const Icon(
                          Icons.format_list_bulleted,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        const Expanded(
                          child: Text(
                            'Lista de Convidados',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: 112, child: campoPesquisa()),
                      ],
                    ),

                    const SizedBox(height: 5),

                    if (convidadosFiltrados.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          termoBusca.isEmpty
                              ? 'Nenhum convidado cadastrado.'
                              : 'Nenhum convidado encontrado.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6A4775),
                            fontSize: 10,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: convidadosFiltrados.length,
                        itemBuilder: (context, index) {
                          final convidado = convidadosFiltrados[index];
                          final totalPessoas = calcularTotalPessoas(convidado);
                          final status =
                              (convidado['status_confirmacao'] ?? 'PENDENTE')
                                  .toString()
                                  .toUpperCase();

                          final corStatus = status == 'CONFIRMADO'
                              ? const Color(0xFF19A957)
                              : status == 'RECUSADO'
                              ? const Color(0xFFE74747)
                              : const Color(0xFFE99A20);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(9),
                              onTap: () => visualizarDetalhes(convidado),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0DDF7),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF8A2BA5),
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            convidado['nome']?.toString() ??
                                                'Sem nome',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF392044),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            convidado['email']?.toString() ??
                                                'Sem e-mail',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF786D7D),
                                              fontSize: 7,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 2,
                                            children: [
                                              _etiquetaConvidado(
                                                '$totalPessoas ${totalPessoas == 1 ? 'pessoa' : 'pessoas'}',
                                                const Color(0xFF8A2BA5),
                                                const Color(0xFFF1E2F7),
                                              ),
                                              _etiquetaConvidado(
                                                status.toLowerCase(),
                                                corStatus,
                                                corStatus.withValues(
                                                  alpha: 0.12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Excluir convidado',
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(
                                        minWidth: 25,
                                        minHeight: 25,
                                      ),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFFF3D62),
                                        size: 15,
                                      ),
                                      onPressed: () => removerConvidado(
                                        convidado['convidado_id'],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF8A2BA5),
                                      size: 17,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÃO DE AÇÃO
  // ============================================================

  Widget _botaoAcao({
    required String texto,
    required IconData icone,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 31,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icone, size: 12),
        label: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD900C7),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ETIQUETA DO CONVIDADO
  // ============================================================

  Widget _etiquetaConvidado(String texto, Color cor, Color fundo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontSize: 6.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
