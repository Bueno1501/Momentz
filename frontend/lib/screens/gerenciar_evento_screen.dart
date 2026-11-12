import 'package:flutter/material.dart';
import 'package:frontend/widgets/page_container.dart';

import 'fornecedores_screen.dart';
import 'galeria_screen.dart';
import 'orcamento_screen.dart';
import 'meus_eventos_screen.dart';

class GerenciarEventoScreen extends StatelessWidget {
  final int eventoId;
  final int usuarioId;
  final Map<String, dynamic> eventoAtual;

  const GerenciarEventoScreen({
    super.key,
    required this.eventoId,
    required this.usuarioId,
    required this.eventoAtual,
  });

  static const Color roxoEscuro = Color(0xFF21002E);
  static const Color roxoMedio = Color(0xFF49105F);
  static const Color magenta = Color(0xFFD000C8);
  static const Color lilas = Color(0xFFF3DDF8);
  static const Color textoRoxo = Color(0xFF351044);

  Widget cardOpcao({
    required BuildContext context,
    required IconData icone,
    required String titulo,
    required String descricao,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      color: const Color(0xFFFFFBFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE52AD4), Color(0xFFD000C8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(icone, color: Colors.white, size: 39),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: textoRoxo,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descricao,
                      style: TextStyle(
                        color: textoRoxo.withValues(alpha: 0.75),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: roxoMedio,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ABRIR MEUS EVENTOS
  // ============================================================

  Future<void> abrirMeusEventos(BuildContext context) async {
    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MeusEventosScreen(usuarioId: usuarioId, eventoAtual: eventoAtual),
      ),
    );

    if (!context.mounted || resultado == null) return;

    // Devolve o evento selecionado para a Home.
    Navigator.pop(context, resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoEscuro,

      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Gerenciar Evento',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD000C8), Color(0xFF8700A8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF21002E), Color(0xFF390044), Color(0xFF21002E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: PageContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 25, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: magenta.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.event_note_rounded,
                        color: Colors.white,
                        size: 43,
                      ),
                    ),

                    const SizedBox(width: 17),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Organize seu evento',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Gerencie os principais recursos do seu evento em um só lugar.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                cardOpcao(
                  context: context,
                  icone: Icons.calendar_month_rounded,
                  titulo: 'Meus Eventos',
                  descricao:
                      'Visualize e acompanhe os detalhes dos seus eventos.',
                  onTap: () => abrirMeusEventos(context),
                ),

                const SizedBox(height: 16),

                cardOpcao(
                  context: context,
                  icone: Icons.groups_rounded,
                  titulo: 'Fornecedores',
                  descricao:
                      'Cadastre e gerencie os fornecedores do seu evento.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FornecedoresScreen(eventoId: eventoId),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                cardOpcao(
                  context: context,
                  icone: Icons.photo_library_rounded,
                  titulo: 'Galeria',
                  descricao: 'Visualize e organize as fotos do seu evento.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GaleriaScreen(eventoId: eventoId),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                cardOpcao(
                  context: context,
                  icone: Icons.account_balance_wallet_rounded,
                  titulo: 'Orçamento',
                  descricao:
                      'Controle os gastos e acompanhe o orçamento do seu evento.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrcamentoScreen(eventoId: eventoId),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                Center(
                  child: Icon(
                    Icons.event_available_rounded,
                    size: 75,
                    color: magenta.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
