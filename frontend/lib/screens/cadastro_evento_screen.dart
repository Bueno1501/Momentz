import 'package:flutter/material.dart';
import 'package:frontend/widgets/page_container.dart';
import '../services/api_service.dart';

class CadastroEventoScreen extends StatefulWidget {
  final int usuarioId;

  const CadastroEventoScreen({super.key, required this.usuarioId});

  @override
  State<CadastroEventoScreen> createState() => _CadastroEventoScreenState();
}

class _CadastroEventoScreenState extends State<CadastroEventoScreen> {
  final tipoController = TextEditingController();

  String? tipoEventoSelecionado;
  final List<String> tipoEvento = [
    'Casamento',
    'Aniversário',
    'Formatura',
    'Chá de bebê',
    'Debutante',
    'Corporativo',
    'Outro',
  ];

  final convidadosController = TextEditingController();
  final descricaoController = TextEditingController();
  final dataController = TextEditingController();
  final localController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();

  DateTime? dataSelecionada;

  Future cadastrarEvento() async {
    if (tipoEventoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecioanar o tipo do evento')),
      );

      return;
    }

    if (dataController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os Campos!!')),
      );
      return;
    }

    final resposta = await ApiService.cadastrarEvento(
      tipoEvento: tipoEventoSelecionado == 'Outro'
          ? tipoController.text
          : tipoEventoSelecionado!,

      quantidadeConvidados: int.parse(convidadosController.text),

      descricao: descricaoController.text,
      dataEvento: dataController.text,
      localEvento: localController.text,
      cidadeEvento: cidadeController.text,
      estadoEvento: estadoController.text,

      usuarioId: widget.usuarioId,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Evento criado!!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(resposta['mensagem']),
            const SizedBox(height: 10),
            Text(
              'Código do Evento: ${resposta['codigo_evento']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK!'),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resposta['mensagem'])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Evento')),

      body: PageContainer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: tipoEventoSelecionado,

                decoration: const InputDecoration(labelText: 'Tipo do Evento'),

                items: tipoEvento.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),

                onChanged: (valor) {
                  setState(() {
                    tipoEventoSelecionado = valor;
                  });
                },
              ),

              const SizedBox(height: 15),

              if (tipoEventoSelecionado == 'Outro')
                TextField(
                  controller: tipoController,

                  decoration: const InputDecoration(
                    labelText: 'Digite o tipo do evento',
                  ),
                ),

              const SizedBox(height: 15),

              TextField(
                controller: convidadosController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade Convidados',
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: dataController,
                readOnly: true,

                decoration: const InputDecoration(
                  labelText: 'Data do Evento',
                  suffixIcon: Icon(Icons.calendar_month),
                ),

                onTap: () async {
                  final data = await showDatePicker(
                    context: context,

                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );

                  if (data != null) {
                    setState(() {
                      dataSelecionada = data;

                      dataController.text =
                          "${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
              ),

              const SizedBox(height: 15),

              TextField(
                controller: localController,
                decoration: const InputDecoration(labelText: 'Local do Evento'),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: cidadeController,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: estadoController,
                decoration: const InputDecoration(labelText: 'Estado'),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: cadastrarEvento,

                child: const Text('Cadastrar Evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
