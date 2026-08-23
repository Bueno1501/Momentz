import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'cadastro_evento_screen.dart';
import 'convidados_screen.dart';
import 'gerenciar_evento_screen.dart';
import 'presentes_screen.dart';
import '../widgets/page_container.dart';
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

  Widget menuCard({
    required IconData icon,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(20),

      child: Card(
        child: SizedBox(
          width: 140,
          height: 90,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(icon, size: 40, color: const Color(0xFFBB86FC)),

              const SizedBox(height: 10),

              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    carregarEvento();
  }

  Future carregarEvento() async {
    final dados = await ApiService.buscarEventoUsuario(widget.usuarioId);

    setState(() {
      evento = dados;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (DidPop, result) async {
        if (DidPop) return;

        final sair = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Encerrar sessão'),

            content: const Text('Deseja realmente sair da sessão ? '),

            actionsAlignment: MainAxisAlignment.center,
            actionsOverflowButtonSpacing: 12,

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Cancelar'),
              ),

              SizedBox(
                width: 90,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Sair'),
                ),
              ),
            ],
          ),
        );

        if (sair == true) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Momentz')),

        body: PageContainer(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                const SizedBox(height: 20),

                Text(
                  'Olá, ${widget.nomeUsuario}! \n' + 'Bem Vindo ao Momentz',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                if (evento != null && evento!.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.celebration,
                            size: 60,
                            color: Color(0xFFBB86FC),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Tipo do Evento: ${evento!['tipo_evento']}',
                            style: const TextStyle(fontSize: 18),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Código: ${evento!['codigo_evento']}',
                            style: const TextStyle(fontSize: 18),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Quantidade de Convidados: ${evento!['quantidade_convidados']}',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                if (evento == null || evento!.isEmpty)
                  SizedBox(
                    width: 320,

                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CadastroEventoScreen(
                              usuarioId: widget.usuarioId,
                            ),
                          ),
                        );

                        await carregarEvento();
                      },
                      child: const Text('Cadastrar Evento'),
                    ),
                  ),

                if (evento != null && evento!.isNotEmpty)
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,

                    children: [
                      menuCard(
                        icon: Icons.settings,
                        titulo: 'Gerenciar',

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GerenciarEventoScreen(
                                eventoId: evento!['evento_id'],
                              ),
                            ),
                          );
                        },
                      ),

                      menuCard(
                        icon: Icons.people,
                        titulo: 'Convidados',

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConvidadosScreen(
                                eventoId: evento!['evento_id'],
                              ),
                            ),
                          );
                        },
                      ),

                      menuCard(
                        icon: Icons.card_giftcard,
                        titulo: 'Presentes',

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PresentesScreen(
                                eventoId: evento!['evento_id'],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
