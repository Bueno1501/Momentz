import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

class PresentesConvidadoScreen extends StatefulWidget {
  const PresentesConvidadoScreen({super.key});

  @override
  State<PresentesConvidadoScreen> createState() =>
      _PresentesConvidadoScreenState();
}

class _PresentesConvidadoScreenState extends State<PresentesConvidadoScreen> {
  static const Color roxoEscuro = Color(0xFF210020);
  static const Color roxo = Color(0xFF50004F);
  static const Color magenta = Color(0xFFE000B8);
  static const Color rosaClaro = Color(0xFFFCE4F8);

  List<dynamic> presentes = [];
  bool carregando = true;
  String? erro;

  @override
  void initState() {
    super.initState();
    _carregarPresentes();
  }

  Future<void> _carregarPresentes() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final resultado = await ApiService.buscarPresentesConvidado();

      if (!mounted) return;

      setState(() {
        presentes = resultado;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erro = e.toString().replaceFirst('Exception: ', '');
        carregando = false;
      });
    }
  }

  IconData _obterIcone(dynamic identificador) {
    const Map<String, IconData> icones = {
      'card_giftcard': Icons.card_giftcard,
      'home': Icons.home_outlined,
      'tv': Icons.tv,
      'phone': Icons.phone_android,
      'computer': Icons.computer,
      'chair': Icons.chair_alt_outlined,
      'bed': Icons.bed_outlined,
      'kitchen': Icons.kitchen_outlined,
      'favorite': Icons.favorite_outline,
      'diamond': Icons.diamond_outlined,
      'flight': Icons.flight,
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe_outlined,
      'celebration': Icons.celebration_outlined,
      'payments': Icons.payments_outlined,
      'shopping_bag': Icons.shopping_bag_outlined,
    };

    return icones[identificador?.toString()] ?? Icons.card_giftcard;
  }

  String _formatarValor(dynamic valor) {
    final numero =
        double.tryParse(valor?.toString().replaceAll(',', '.') ?? '') ?? 0;

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  bool _ehListaExterna(Map<String, dynamic> presente) {
    return presente['tipo_presente']?.toString() == 'LISTA_EXTERNA';
  }

  Future<void> _abrirListaExterna(Map<String, dynamic> presente) async {
    final link = presente['link_loja']?.toString().trim() ?? '';

    if (link.isEmpty) {
      _mostrarMensagem('Este presente não possui um link cadastrado.');
      return;
    }

    final uri = Uri.tryParse(link);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      _mostrarMensagem('O link deste presente é inválido.');
      return;
    }

    try {
      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!abriu && mounted) {
        _mostrarMensagem('Não foi possível abrir o link.');
      }
    } catch (_) {
      if (mounted) {
        _mostrarMensagem('Não foi possível abrir o link.');
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: roxo));
  }

  void _selecionarPresente(Map<String, dynamic> presente) {
    if (_ehListaExterna(presente)) {
      _abrirListaExterna(presente);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesPresenteConvidadoScreen(
          presente: presente,
          obterIcone: _obterIcone,
          formatarValor: _formatarValor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoEscuro,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/momentz_fundo_desktop.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: roxoEscuro),
            ),
          ),

          Positioned.fill(
            child: Container(color: roxoEscuro.withValues(alpha: 0.48)),
          ),

          SafeArea(
            child: Column(
              children: [
                _cabecalho(),

                Expanded(
                  child: RefreshIndicator(
                    color: magenta,
                    onRefresh: _carregarPresentes,
                    child: _conteudo(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFED00C4), Color(0xFF800080), Color(0xFFED00C4)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          ),

          const Spacer(),

          const Text(
            'MOMENTZ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const Spacer(),

          IconButton(
            onPressed: _carregarPresentes,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 27),
          ),
        ],
      ),
    );
  }

  Widget _conteudo() {
    if (carregando) {
      return const Center(child: CircularProgressIndicator(color: magenta));
    }

    if (erro != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          _estado(
            icone: Icons.error_outline,
            titulo: 'Não foi possível carregar os presentes',
            descricao: erro!,
            botao: 'Tentar novamente',
            acao: _carregarPresentes,
          ),
        ],
      );
    }

    if (presentes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          _estado(
            icone: Icons.card_giftcard,
            titulo: 'Ainda não há presentes',
            descricao:
                'O administrador ainda não cadastrou presentes para este evento.',
            botao: 'Atualizar',
            acao: _carregarPresentes,
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 800;

        final larguraCard = desktop ? 280.0 : 165.0;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 45 : 18,
            vertical: 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Lista de Presentes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Escolha um presente e faça parte deste momento especial!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  const SizedBox(height: 30),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    runSpacing: 18,
                    children: presentes.map((item) {
                      final presente = Map<String, dynamic>.from(item as Map);

                      return SizedBox(
                        width: larguraCard,
                        child: _cardPresente(presente),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cardPresente(Map<String, dynamic> presente) {
    final nome = presente['nome_presente']?.toString() ?? 'Presente';

    final externo = _ehListaExterna(presente);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selecionarPresente(presente),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: rosaClaro, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 85,
                width: 85,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF35C9), Color(0xFFB000A8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _obterIcone(presente['icone']),
                  color: Colors.white,
                  size: 45,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: roxoEscuro,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (!externo)
                Text(
                  _formatarValor(presente['valor']),
                  style: const TextStyle(
                    color: magenta,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text(
                  'Ver lista externa',
                  style: TextStyle(
                    color: roxo,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const SizedBox(height: 13),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: magenta,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  externo ? 'Acessar lista' : 'Presentear',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estado({
    required IconData icone,
    required String titulo,
    required String descricao,
    required String botao,
    required VoidCallback acao,
  }) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Icon(icone, color: Colors.white, size: 65),
          const SizedBox(height: 18),

          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            descricao,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),

          const SizedBox(height: 22),

          ElevatedButton(
            onPressed: acao,
            style: ElevatedButton.styleFrom(
              backgroundColor: magenta,
              foregroundColor: Colors.white,
            ),
            child: Text(botao),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DETALHES DO PRESENTE
// ============================================================

class DetalhesPresenteConvidadoScreen extends StatefulWidget {
  final Map<String, dynamic> presente;
  final IconData Function(dynamic) obterIcone;
  final String Function(dynamic) formatarValor;

  const DetalhesPresenteConvidadoScreen({
    super.key,
    required this.presente,
    required this.obterIcone,
    required this.formatarValor,
  });

  @override
  State<DetalhesPresenteConvidadoScreen> createState() =>
      _DetalhesPresenteConvidadoScreenState();
}

class _DetalhesPresenteConvidadoScreenState
    extends State<DetalhesPresenteConvidadoScreen> {
  static const Color roxoEscuro = Color(0xFF210020);
  static const Color roxo = Color(0xFF50004F);
  static const Color magenta = Color(0xFFE000B8);

  final TextEditingController mensagemController = TextEditingController();

  @override
  void dispose() {
    mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presente = widget.presente;

    final nome = presente['nome_presente']?.toString() ?? 'Presente';

    final descricao =
        presente['descricao']?.toString() ??
        'Um presente especial para este momento.';

    return Scaffold(
      backgroundColor: roxoEscuro,
      appBar: AppBar(
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detalhes do presente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 800;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: desktop ? 35 : 20,
              vertical: 25,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 130,
                        width: 130,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF35C9), Color(0xFFB000A8)],
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Icon(
                          widget.obterIcone(presente['icone']),
                          color: Colors.white,
                          size: 75,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        nome,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: roxoEscuro,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        widget.formatarValor(presente['valor']),
                        style: const TextStyle(
                          color: magenta,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Sobre o presente',
                          style: TextStyle(
                            color: roxoEscuro,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          descricao,
                          style: const TextStyle(
                            color: roxo,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Deixe uma mensagem (opcional)',
                          style: TextStyle(
                            color: roxoEscuro,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: mensagemController,
                        maxLength: 300,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Escreva uma mensagem especial...',
                          filled: true,
                          fillColor: const Color(0xFFFCE4F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE4F8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          'O pagamento será realizado pelo ambiente seguro do MOMENTZ.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: roxo, fontSize: 14),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'A integração do pagamento será implementada na próxima etapa.',
                                ),
                                backgroundColor: roxo,
                              ),
                            );
                          },
                          icon: const Icon(Icons.card_giftcard),
                          label: const Text(
                            'Presentear',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: magenta,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
