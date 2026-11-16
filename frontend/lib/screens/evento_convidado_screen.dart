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

  String _texto(dynamic valor) {
    final texto = valor?.toString().trim() ?? '';
    return texto.isEmpty ? '-' : texto;
  }

  String _formatarData(dynamic valor) {
    final texto = valor?.toString().trim() ?? '';

    if (texto.isEmpty) return '-';

    final data = DateTime.tryParse(texto);

    if (data == null) return texto;

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoEscuro,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool desktop = constraints.maxWidth >= 800;

          return Stack(
            fit: StackFit.expand,
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
                    _cabecalho(context, desktop),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 40 : 14,
                          vertical: desktop ? 30 : 20,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1050),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _boasVindas(desktop),
                                const SizedBox(height: 25),
                                _informacoesEvento(desktop),
                                const SizedBox(height: 25),

                                _opcao(
                                  desktop: desktop,
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
                                  desktop: desktop,
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
                                  desktop: desktop,
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
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            child: const Text(
                                              'Cancelar',
                                              style: TextStyle(
                                                color: roxo,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: magenta,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            child: const Text('Sim'),
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

  Widget _cabecalho(BuildContext context, bool desktop) {
    return Container(
      height: desktop ? 85 : 68,
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
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: desktop ? 35 : 28,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.photo_camera_outlined,
            color: Colors.white,
            size: desktop ? 48 : 33,
          ),
          const SizedBox(width: 9),
          Text(
            'MOMENTZ',
            style: TextStyle(
              color: Colors.white,
              fontSize: desktop ? 30 : 23,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _boasVindas(bool desktop) {
    final nomeAdministrador = _texto(evento['nome_administrador'] ?? 'Evento');

    return Row(
      children: [
        Container(
          height: desktop ? 105 : 72,
          width: desktop ? 105 : 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF35C9), Color(0xFFB000A8)],
            ),
            borderRadius: BorderRadius.circular(desktop ? 28 : 20),
          ),
          child: Icon(
            Icons.celebration,
            color: Colors.white,
            size: desktop ? 55 : 38,
          ),
        ),
        SizedBox(width: desktop ? 20 : 12),
        Expanded(
          child: Container(
            padding: EdgeInsets.only(left: desktop ? 18 : 12),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: magenta, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo ao evento de',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: desktop ? 22 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  nomeAdministrador,
                  softWrap: true,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: desktop ? 34 : 23,
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

  Widget _informacoesEvento(bool desktop) {
    final tipo = _texto(evento['tipo_evento']);

    return Container(
      padding: EdgeInsets.all(desktop ? 22 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _iconeInformacao(Icons.calendar_month, desktop),
              SizedBox(width: desktop ? 18 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipo,
                      style: TextStyle(
                        color: roxoEscuro,
                        fontSize: desktop ? 25 : 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Informações do evento',
                      style: TextStyle(
                        color: roxo,
                        fontSize: desktop ? 17 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: desktop ? 17 : 10,
                  vertical: desktop ? 10 : 7,
                ),
                decoration: BoxDecoration(
                  color: rosaClaro,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 10),
                    const SizedBox(width: 5),
                    Text(
                      'Ativo',
                      style: TextStyle(
                        color: roxoEscuro,
                        fontSize: desktop ? 14 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _linhaInformacao(
            Icons.confirmation_number_outlined,
            'Código do evento',
            evento['codigo_evento'],
            desktop,
          ),

          _linhaInformacao(
            Icons.calendar_today_outlined,
            'Data do evento',
            _formatarData(evento['data_evento']),
            desktop,
          ),

          _linhaInformacao(
            Icons.location_on_outlined,
            'Local do evento',
            evento['local_evento'],
            desktop,
          ),

          _linhaInformacao(
            Icons.map_outlined,
            'Cidade / Estado',
            '${_texto(evento['cidade_evento'])} / '
                '${_texto(evento['estado_evento'])}',
            desktop,
          ),
        ],
      ),
    );
  }

  Widget _iconeInformacao(IconData icone, bool desktop) {
    return Container(
      height: desktop ? 85 : 58,
      width: desktop ? 85 : 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF7DDF5),
        borderRadius: BorderRadius.circular(desktop ? 24 : 17),
      ),
      child: Icon(icone, color: roxo, size: desktop ? 45 : 32),
    );
  }

  Widget _linhaInformacao(
    IconData icone,
    String titulo,
    dynamic valor,
    bool desktop,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 15 : 11,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9E3F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 430;

          final iconeWidget = Icon(icone, color: roxo, size: desktop ? 27 : 23);

          final tituloWidget = Text(
            titulo,
            style: TextStyle(color: roxoEscuro, fontSize: desktop ? 15 : 14),
          );

          final valorWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0C6EB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _texto(valor),
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                color: roxoEscuro,
                fontSize: desktop ? 14 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          if (compacto) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconeWidget,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: tituloWidget,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: valorWidget,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              iconeWidget,
              const SizedBox(width: 15),
              Expanded(child: tituloWidget),
              const SizedBox(width: 10),
              Flexible(child: valorWidget),
            ],
          );
        },
      ),
    );
  }

  Widget _opcao({
    required bool desktop,
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
          constraints: BoxConstraints(minHeight: desktop ? 135 : 105),
          padding: EdgeInsets.all(desktop ? 18 : 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Container(
                height: desktop ? 100 : 65,
                width: desktop ? 100 : 65,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF35C9), Color(0xFFB000A8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icone,
                  color: Colors.white,
                  size: desktop ? 55 : 35,
                ),
              ),
              SizedBox(width: desktop ? 18 : 10),
              Container(
                height: desktop ? 85 : 65,
                width: 4,
                color: const Color(0xFFE96BD6),
              ),
              SizedBox(width: desktop ? 18 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: roxoEscuro,
                        fontSize: desktop ? 24 : 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      descricao,
                      style: TextStyle(
                        color: roxo,
                        fontSize: desktop ? 15 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: roxoEscuro,
                size: desktop ? 38 : 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
