import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'cadastro_evento_screen.dart';
import 'convidados_screen.dart';
import 'gerenciar_evento_screen.dart';
import 'presentes_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final int usuarioId;
  final String nomeUsuario;

  const HomeScreen({
    super.key,
    required this.usuarioId,
    required this.nomeUsuario,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? evento;

  static const Color roxoEscuro = Color(0xFF21002E);
  static const Color roxo = Color(0xFF48005C);
  static const Color magenta = Color(0xFFEC00C8);
  static const Color rosa = Color(0xFFFF36D2);
  static const Color lilas = Color(0xFFF7DFFF);
  static const Color textoEscuro = Color(0xFF310B3D);

  @override
  void initState() {
    super.initState();
    carregarEvento();
  }

  Future<void> carregarEvento() async {
    try {
      final dados = await ApiService.buscarEventoUsuario(widget.usuarioId);

      if (!mounted) return;

      setState(() {
        evento = dados;
      });
    } catch (e) {
      debugPrint('Erro ao carregar evento: $e');

      if (!mounted) return;

      setState(() {
        evento = {};
      });
    }
  }

  Future<void> confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF30003D),

        title: const Text(
          'Encerrar sessão',
          style: TextStyle(color: Colors.white),
        ),

        content: const Text(
          'Deseja realmente sair da sessão?',
          style: TextStyle(color: Colors.white70),
        ),

        actionsAlignment: MainAxisAlignment.center,

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar', style: TextStyle(color: rosa)),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: magenta,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (sair == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget linhaInformacao({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),

      decoration: BoxDecoration(
        color: const Color(0xFFF9E3FA),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        children: [
          Icon(icone, color: roxo, size: 27),

          const SizedBox(width: 15),

          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ),

          Flexible(
            child: Container(
              constraints: const BoxConstraints(minWidth: 45),

              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),

              decoration: BoxDecoration(
                color: const Color(0xFFF1C9F5),
                borderRadius: BorderRadius.circular(25),
              ),

              child: Text(
                valor,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: roxoEscuro,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget cardEvento() {
    final tipoEvento = evento?['tipo_evento']?.toString() ?? '';

    final codigoEvento = evento?['codigo_evento']?.toString() ?? '';

    final quantidade = evento?['quantidade_convidados']?.toString() ?? '-';

    final dataEvento = evento?['data_evento']?.toString() ?? '-';

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),

        boxShadow: [
          BoxShadow(
            color: magenta.withValues(alpha: 0.13),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,

                decoration: BoxDecoration(
                  color: lilas,
                  borderRadius: BorderRadius.circular(25),
                ),

                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 42,
                  color: roxo,
                ),
              ),

              const SizedBox(width: 12),

              Container(width: 3, height: 60, color: magenta),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      tipoEvento,

                      style: const TextStyle(
                        color: textoEscuro,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Detalhes do seu evento',

                      style: TextStyle(color: textoEscuro, fontSize: 14),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),

                decoration: BoxDecoration(
                  color: lilas,
                  borderRadius: BorderRadius.circular(25),
                ),

                child: const Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Icon(Icons.circle, color: Color(0xFF20D52D), size: 12),

                    SizedBox(width: 6),

                    Text(
                      'Ativo',

                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          linhaInformacao(
            icone: Icons.confirmation_number_outlined,
            titulo: 'Código do evento',
            valor: codigoEvento,
          ),

          linhaInformacao(
            icone: Icons.people_outline,
            titulo: 'Quantidade de convidados',
            valor: quantidade,
          ),

          linhaInformacao(
            icone: Icons.calendar_today_outlined,
            titulo: 'Data do evento',
            valor: dataEvento == 'null' ? '-' : dataEvento,
          ),
        ],
      ),
    );
  }

  Widget iconeMenu(IconData icone) {
    return Container(
      width: 75,
      height: 75,

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3AD4), Color(0xFFD500C2)],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: magenta.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Icon(icone, color: Colors.white, size: 40),
    );
  }

  Widget menuCard({
    required IconData icone,
    required String titulo,
    required String descricao,
    required VoidCallback onTap,
    bool larguraTotal = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),

            boxShadow: [
              BoxShadow(
                color: magenta.withValues(alpha: 0.10),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: larguraTotal
              ? Row(
                  children: [
                    iconeMenu(icone),

                    const SizedBox(width: 18),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            titulo,

                            style: const TextStyle(
                              color: textoEscuro,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            descricao,

                            style: const TextStyle(
                              color: textoEscuro,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.chevron_right, color: roxo, size: 35),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        iconeMenu(icone),

                        const Spacer(),

                        const Icon(Icons.chevron_right, color: roxo, size: 35),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Text(
                      titulo,

                      style: const TextStyle(
                        color: textoEscuro,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      descricao,

                      style: const TextStyle(
                        color: textoEscuro,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget cabecalho() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD900C7), Color(0xFF78008E), Color(0xFFD900C7)],
        ),
      ),

      child: Row(
        children: [
          IconButton(
            onPressed: confirmarSaida,

            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          ),

          const Spacer(),

          const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 39),

          const SizedBox(width: 12),

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

          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget saudacao() {
    final nome = widget.nomeUsuario.trim();

    final primeiroNome = nome.isEmpty ? 'Administrador' : nome.split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 25),

      child: Row(
        children: [
          Container(
            width: 85,
            height: 85,

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF35D4), Color(0xFFB000B9)],
              ),

              borderRadius: BorderRadius.circular(27),
            ),

            child: const Icon(
              Icons.celebration_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Olá, $primeiroNome!',

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Bem-vindo ao MOMENTZ ✨',

                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget menuResponsivo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Duas colunas somente quando houver espaço suficiente.

        final bool duasColunas = constraints.maxWidth >= 600;

        final cardGerenciar = menuCard(
          icone: Icons.settings_outlined,
          titulo: 'Gerenciar Evento',
          descricao: 'Edite as informações do seu evento',

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GerenciarEventoScreen(eventoId: evento!['evento_id']),
              ),
            );
          },
        );

        final cardConvidados = menuCard(
          icone: Icons.people_outline,
          titulo: 'Convidados',
          descricao: 'Cadastre e gerencie os convidados',

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ConvidadosScreen(eventoId: evento!['evento_id']),
              ),
            );
          },
        );

        final cardPresentes = menuCard(
          icone: Icons.card_giftcard,
          titulo: 'Presentes',
          descricao: 'Crie sua lista e receba os presentes',

          larguraTotal: true,

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PresentesScreen(eventoId: evento!['evento_id']),
              ),
            );
          },
        );

        if (duasColunas) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Expanded(child: cardGerenciar),

                  const SizedBox(width: 16),

                  Expanded(child: cardConvidados),
                ],
              ),

              const SizedBox(height: 16),

              cardPresentes,
            ],
          );
        }

        return Column(
          children: [
            cardGerenciar,

            const SizedBox(height: 16),

            cardConvidados,

            const SizedBox(height: 16),

            cardPresentes,
          ],
        );
      },
    );
  }

  Widget botaoCadastrarEvento() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),

        child: SizedBox(
          width: double.infinity,

          child: ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CadastroEventoScreen(usuarioId: widget.usuarioId),
                ),
              );

              await carregarEvento();
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: magenta,
              foregroundColor: Colors.white,

              padding: const EdgeInsets.symmetric(vertical: 20),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            child: const Text(
              'Cadastrar Evento',

              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        await confirmarSaida();
      },

      child: Scaffold(
        backgroundColor: roxoEscuro,

        body: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWeb = constraints.maxWidth >= 700;

            final double panelWidth = isWeb
                ? (constraints.maxWidth < 900 ? constraints.maxWidth : 900.0)
                : constraints.maxWidth;

            return Container(
              width: double.infinity,
              height: double.infinity,

              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,

                  colors: [
                    Color(0xFF160020),
                    Color(0xFF30003D),
                    Color(0xFF160020),
                  ],
                ),
              ),

              child: Center(
                child: Container(
                  width: panelWidth,
                  height: constraints.maxHeight,

                  clipBehavior: Clip.antiAlias,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isWeb ? 18 : 0),

                    boxShadow: isWeb
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),

                  child: Stack(
                    fit: StackFit.expand,

                    children: [
                      Image.asset(
                        'assets/images/fundo_home.png',

                        fit: BoxFit.cover,

                        alignment: Alignment.center,

                        errorBuilder: (_, __, ___) {
                          return Container(color: roxoEscuro);
                        },
                      ),

                      Container(color: Colors.black.withValues(alpha: 0.08)),

                      SafeArea(
                        child: Column(
                          children: [
                            cabecalho(),

                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),

                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 950,
                                    ),

                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 10,
                                      ),

                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [
                                          saudacao(),

                                          if (evento == null)
                                            const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(35),

                                                child:
                                                    CircularProgressIndicator(
                                                      color: rosa,
                                                    ),
                                              ),
                                            ),

                                          if (evento != null &&
                                              evento!.isNotEmpty) ...[
                                            cardEvento(),

                                            const SizedBox(height: 25),

                                            menuResponsivo(),
                                          ],

                                          if (evento != null &&
                                              evento!.isEmpty) ...[
                                            const SizedBox(height: 20),

                                            botaoCadastrarEvento(),
                                          ],

                                          const SizedBox(height: 60),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
