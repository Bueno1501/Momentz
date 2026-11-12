import 'package:flutter/material.dart';
import 'cadastro_usuario_screen.dart';
import 'galeria_convidado_screen.dart';
import 'presentes_convidado_screen.dart';

class EventoConvidadoScreen extends StatelessWidget {
  final Map<String, dynamic> evento;

  const EventoConvidadoScreen({super.key, required this.evento});

  static const Color roxoEscuro = Color(0xFF210020);
  static const Color roxo = Color(0xFF50004F);
  static const Color magenta = Color(0xFFE000B8);
  static const Color rosaClaro = Color(0xFFFCE4F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoEscuro,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool desktop = constraints.maxWidth >= 800;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  desktop
                      ? 'assets/images/momentz_fundo_desktop.png'
                      : 'assets/images/momentz_fundo_mobile.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    _cabecalho(context),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 40 : 18,
                          vertical: 25,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1050),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _boasVindas(),

                                const SizedBox(height: 28),

                                _informacoesEvento(),

                                const SizedBox(height: 25),

                                _opcao(
                                  icone: Icons.photo_library_outlined,
                                  titulo: 'Galeria',
                                  descricao:
                                      'Veja suas fotos e compartilhe momentos do evento',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const GaleriaConvidadoScreen(),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 16),

                                _opcao(
                                  icone: Icons.card_giftcard,
                                  titulo: 'Presentes',
                                  descricao: 'Confira os presentes do evento',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PresentesConvidadoScreen(),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 16),

                                _opcao(
                                  icone: Icons.add_circle_outline,
                                  titulo: 'Criar Evento',
                                  descricao:
                                      'Cadastre um novo evento no Momentz',

                                  onTap: () async {
                                    final bool?
                                    confirmou = await showDialog<bool>(
                                      context: context,

                                      builder: (dialogContext) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        surfaceTintColor: Colors.white,
                                        elevation: 12,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                        ),
                                        title: const Text(
                                          'Criar uma conta',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                            color: roxoEscuro,
                                          ),
                                        ),
                                        content: const Text(
                                          'Você tem certeza que deseja prosseguir para criar uma conta no MOMENTZ?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: roxo,
                                          ),
                                        ),
                                        actionsAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        actionsPadding:
                                            const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              18,
                                            ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                dialogContext,
                                                false,
                                              );
                                            },
                                            child: const Text(
                                              'Cancelar',
                                              style: TextStyle(
                                                color: roxo,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: magenta,
                                              foregroundColor: Colors.white,
                                              elevation: 3,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 32,
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(
                                                dialogContext,
                                                true,
                                              );
                                            },
                                            child: const Text(
                                              'Sim',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmou == true && context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CadastroUsuarioScreen(),
                                        ),
                                      );
                                    }
                                  },
                                ),

                                const SizedBox(height: 25),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cabecalho(BuildContext context) {
    return Container(
      height: 85,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFED00C4), Color(0xFF800080), Color(0xFFED00C4)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 35),
          ),

          const Spacer(),

          const Icon(
            Icons.photo_camera_outlined,
            color: Colors.white,
            size: 48,
          ),

          const SizedBox(width: 12),

          const Text(
            'MOMENTZ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const Spacer(),

          const SizedBox(width: 45),
        ],
      ),
    );
  }

  Widget _boasVindas() {
    final String nomeAdministrador = (evento['nome_administrador'] ?? 'Evento')
        .toString();

    return Row(
      children: [
        Container(
          height: 105,
          width: 105,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF35C9), Color(0xFFB000A8)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(Icons.celebration, color: Colors.white, size: 55),
        ),

        const SizedBox(width: 20),

        Expanded(
          child: Container(
            padding: const EdgeInsets.only(left: 18),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: magenta, width: 5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bem-vindo ao evento de',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  nomeAdministrador,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _informacoesEvento() {
    final String tipo = (evento['tipo_evento'] ?? 'Evento').toString();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _iconeInformacao(Icons.calendar_month),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipo,
                      style: const TextStyle(
                        color: roxoEscuro,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Text(
                      'Informações do evento',
                      style: TextStyle(color: roxo, fontSize: 17),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: rosaClaro,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 13),
                    SizedBox(width: 8),
                    Text(
                      'Ativo',
                      style: TextStyle(
                        color: roxoEscuro,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          _linhaInformacao(
            Icons.confirmation_number_outlined,
            'Código do evento',
            evento['codigo_evento'],
          ),

          _linhaInformacao(
            Icons.people_outline,
            'Quantidade de convidados',
            evento['quantidade_convidados'],
          ),

          _linhaInformacao(
            Icons.calendar_today_outlined,
            'Data do evento',
            evento['data_evento'],
          ),

          _linhaInformacao(
            Icons.location_on_outlined,
            'Local do evento',
            evento['local_evento'],
          ),

          _linhaInformacao(
            Icons.map_outlined,
            'Cidade / Estado',
            '${evento['cidade_evento'] ?? '-'} / '
                '${evento['estado_evento'] ?? '-'}',
          ),
        ],
      ),
    );
  }

  Widget _iconeInformacao(IconData icone) {
    return Container(
      height: 85,
      width: 85,
      decoration: BoxDecoration(
        color: const Color(0xFFF7DDF5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icone, color: roxo, size: 45),
    );
  }

  Widget _linhaInformacao(IconData icone, String titulo, dynamic valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9E3F7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icone, color: roxo, size: 27),

          const SizedBox(width: 15),

          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: roxoEscuro, fontSize: 15),
            ),
          ),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF0C6EB),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                valor?.toString() ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: roxoEscuro,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opcao({
    required IconData icone,
    required String titulo,
    required String descricao,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          constraints: const BoxConstraints(minHeight: 135),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF35C9), Color(0xFFB000A8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icone, color: Colors.white, size: 55),
              ),

              const SizedBox(width: 18),

              Container(height: 85, width: 5, color: const Color(0xFFE96BD6)),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: roxoEscuro,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      descricao,
                      style: const TextStyle(color: roxo, fontSize: 15),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: roxoEscuro, size: 38),
            ],
          ),
        ),
      ),
    );
  }

  void _mensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: roxo));
  }
}
