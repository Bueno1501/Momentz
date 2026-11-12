import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'cadastro_evento_screen.dart';

class MeusEventosScreen extends StatefulWidget {
  final int usuarioId;
  final Map<String, dynamic>? eventoAtual;

  const MeusEventosScreen({
    super.key,
    required this.usuarioId,
    this.eventoAtual,
  });

  @override
  State<MeusEventosScreen> createState() => _MeusEventosScreenState();
}

class _MeusEventosScreenState extends State<MeusEventosScreen> {
  List<dynamic> eventos = [];

  bool carregando = true;
  bool abrindoCadastro = false;
  String? erro;

  static const Color roxoEscuro = Color(0xFF160D2B);
  static const Color roxoMedio = Color(0xFF321653);
  static const Color magenta = Color(0xFFE83E9B);
  static const Color lilas = Color(0xFFBCA4FF);

  int? get eventoAtualId {
    final id = widget.eventoAtual?['evento_id'];
    return id == null ? null : int.tryParse(id.toString());
  }

  @override
  void initState() {
    super.initState();
    carregarEventos();
  }

  // ============================================================
  // BUSCAR EVENTOS DO ADMINISTRADOR
  // ============================================================

  Future<void> carregarEventos() async {
    if (!mounted) return;

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final resultado = await ApiService.buscarEventoUsuario();

      if (!mounted) return;

      setState(() {
        eventos = resultado;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erro = e.toString();
        carregando = false;
      });

      debugPrint('Erro ao carregar eventos: $e');
    }
  }

  // ============================================================
  // FORMATAR DATA
  // ============================================================

  String formatarData(dynamic data) {
    if (data == null || data.toString().isEmpty) {
      return 'Data não informada';
    }

    final dataConvertida = DateTime.tryParse(data.toString());

    if (dataConvertida == null) {
      return data.toString();
    }

    final dia = dataConvertida.day.toString().padLeft(2, '0');
    final mes = dataConvertida.month.toString().padLeft(2, '0');
    final ano = dataConvertida.year;

    return '$dia/$mes/$ano';
  }

  // ============================================================
  // CONFIRMAR TROCA DE EVENTO
  // ============================================================

  Future<void> selecionarEvento(Map<String, dynamic> evento) async {
    final idSelecionado = int.tryParse(evento['evento_id'].toString());

    if (idSelecionado == null) {
      mostrarMensagem('Não foi possível identificar este evento.');
      return;
    }

    // Se já é o evento atual, apenas retorna para a Home.
    if (idSelecionado == eventoAtualId) {
      Navigator.pop(context, evento);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: roxoMedio,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Alterar evento?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Deseja realmente alterar o evento atual para '
            '"${evento['tipo_evento'] ?? 'Novo evento'}"?',
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Não', style: TextStyle(color: lilas)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: magenta,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sim, alterar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true) return;

    // Retorna o evento selecionado para a Home.
    Navigator.pop(context, evento);
  }

  // ============================================================
  // CADASTRAR NOVO EVENTO
  // ============================================================

  Future<void> cadastrarNovoEvento() async {
    if (abrindoCadastro) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: roxoMedio,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cadastrar novo evento?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Deseja prosseguir para a tela de cadastro de um novo evento?',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Não', style: TextStyle(color: lilas)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: magenta,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sim, continuar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true) return;

    setState(() {
      abrindoCadastro = true;
    });

    try {
      final resultado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CadastroEventoScreen(usuarioId: widget.usuarioId),
        ),
      );

      if (!mounted) return;

      // O cadastro retorna true quando é concluído.
      if (resultado == true) {
        await carregarEventos();

        if (!mounted) return;

        mostrarMensagem('Novo evento cadastrado com sucesso!');
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Erro ao abrir cadastro de evento: $e');

      mostrarMensagem('Não foi possível abrir o cadastro de evento.');
    } finally {
      if (mounted) {
        setState(() {
          abrindoCadastro = false;
        });
      }
    }
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: roxoMedio,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ÍCONE DO EVENTO
  // ============================================================

  IconData obterIcone(String tipo) {
    final tipoFormatado = tipo.toLowerCase();

    if (tipoFormatado.contains('casamento')) {
      return Icons.favorite;
    }

    if (tipoFormatado.contains('aniversário') ||
        tipoFormatado.contains('aniversario')) {
      return Icons.cake;
    }

    if (tipoFormatado.contains('formatura')) {
      return Icons.school;
    }

    if (tipoFormatado.contains('debutante')) {
      return Icons.auto_awesome;
    }

    return Icons.celebration;
  }

  // ============================================================
  // CARD DO EVENTO
  // ============================================================

  Widget construirCardEvento(Map<String, dynamic> evento) {
    final tipo = evento['tipo_evento']?.toString() ?? 'Evento';

    final codigo = evento['codigo_evento']?.toString() ?? 'Não informado';

    final local = evento['local_evento']?.toString() ?? 'Local não informado';

    final cidade = evento['cidade_evento']?.toString() ?? '';
    final estado = evento['estado_evento']?.toString() ?? '';

    final localCompleto = [
      local,
      if (cidade.isNotEmpty) cidade,
      if (estado.isNotEmpty) estado,
    ].join(' - ');

    final id = int.tryParse(evento['evento_id'].toString());
    final selecionado = id != null && id == eventoAtualId;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF28143E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selecionado ? magenta : lilas.withOpacity(0.22),
          width: selecionado ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE83E9B), Color(0xFF8B42C8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(obterIcone(tipo), color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Código: $codigo',
                        style: const TextStyle(color: lilas, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (selecionado)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 25,
                  )
                else
                  const Icon(Icons.auto_awesome, color: magenta, size: 22),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFF59416D), height: 1),
            const SizedBox(height: 17),

            Row(
              children: [
                const Icon(Icons.calendar_month, color: magenta, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatarData(evento['data_evento']),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: magenta,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localCompleto,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.people_outline, color: magenta, size: 19),
                const SizedBox(width: 10),
                Text(
                  '${evento['quantidade_convidados'] ?? 0} convidados previstos',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => selecionarEvento(evento),
                icon: Icon(selecionado ? Icons.check : Icons.swap_horiz),
                label: Text(
                  selecionado ? 'Evento atual' : 'Selecionar evento',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selecionado ? roxoMedio : magenta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO CADASTRAR EVENTO
  // ============================================================

  Widget construirBotaoCadastrar() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: abrindoCadastro ? null : cadastrarNovoEvento,
        icon: abrindoCadastro
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_circle_outline),
        label: Text(
          abrindoCadastro ? 'Abrindo cadastro...' : 'Cadastrar novo evento',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: magenta,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  // ============================================================
  // SEM EVENTOS
  // ============================================================

  Widget construirSemEventos() {
    return Column(
      children: [
        const SizedBox(height: 35),
        const Icon(Icons.event_busy, color: lilas, size: 75),
        const SizedBox(height: 20),
        const Text(
          'Você ainda não possui eventos',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Cadastre seu primeiro evento para começar a organizar '
          'seus momentos especiais.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget construirErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: magenta, size: 65),
            const SizedBox(height: 18),
            const Text(
              'Não foi possível carregar seus eventos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              erro ?? 'Ocorreu um erro inesperado.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: carregarEventos,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: magenta,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoEscuro,
      appBar: AppBar(
        backgroundColor: roxoEscuro,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Meus Eventos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: carregando ? null : carregarEventos,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Atualizar eventos',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [roxoEscuro, roxoMedio, roxoEscuro],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seus momentos especiais',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecione o evento que deseja gerenciar.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 25),

                  Expanded(
                    child: carregando
                        ? const Center(
                            child: CircularProgressIndicator(color: magenta),
                          )
                        : erro != null
                        ? construirErro()
                        : RefreshIndicator(
                            color: magenta,
                            onRefresh: carregarEventos,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                if (eventos.isEmpty)
                                  construirSemEventos()
                                else
                                  ...eventos.map((item) {
                                    final evento = Map<String, dynamic>.from(
                                      item,
                                    );

                                    return construirCardEvento(evento);
                                  }),

                                const SizedBox(height: 8),
                                construirBotaoCadastrar(),
                                const SizedBox(height: 25),
                              ],
                            ),
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
}
