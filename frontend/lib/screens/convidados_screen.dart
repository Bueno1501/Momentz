import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/page_container.dart';

class ConvidadosScreen extends StatefulWidget {
  final int eventoId;

  const ConvidadosScreen({super.key, required this.eventoId});

  @override
  State<ConvidadosScreen> createState() => _ConvidadosScreenState();
}

class _ConvidadosScreenState extends State<ConvidadosScreen> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();

  List convidados = [];

  Future atualizarStatus(int convidadoId, String status) async {
    await ApiService.alterarStatusConvidado(
      convidadoId: convidadoId,
      status: status,
    );

    await carregarConvidados();
  }

  Future carregarConvidados() async {
    final lista = await ApiService.buscarConvidados(widget.eventoId);

    setState(() {
      convidados = lista;
    });
  }

  @override
  void initState() {
    super.initState();
    carregarConvidados();
  }

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

    await carregarConvidados();
  }

  Future removerConvidado(int convidadoId) async {
    await ApiService.excluirConvidado(convidadoId);

    await carregarConvidados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Convidados')),

      body: PageContainer(
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Convidado'),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email do Convidado',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: adicionarConvidado,
              child: const Text('Adicionar Convidado'),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: convidados.length,

                itemBuilder: (context, index) {
                  final convidado = convidados[index];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 6),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            convidado['nome'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  convidado['email'],
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),

                              IconButton(
                                tooltip: 'Excluir',

                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),

                                onPressed: () {
                                  removerConvidado(convidado['convidado_id']);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
