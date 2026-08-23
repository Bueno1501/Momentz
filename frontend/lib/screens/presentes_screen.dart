import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/page_container.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

class PresentesScreen extends StatefulWidget {
  final int eventoId;

  const PresentesScreen({super.key, required this.eventoId});

  @override
  State<PresentesScreen> createState() => _PresentesScreenState();
}

class _PresentesScreenState extends State<PresentesScreen> {
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final valorController = TextEditingController();
  final linkController = TextEditingController();

  final valorFormatter = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    decimalDigits: 2,
    symbol: 'R\$',
  );

  List presentes = [];

  @override
  void initState() {
    super.initState();
    carregarPresentes();
  }

  Future carregarPresentes() async {
    final lista = await ApiService.buscarPresentes(widget.eventoId);

    setState(() {
      presentes = lista;
    });
  }

  Future adicionarPresente() async {
    final resposta = await ApiService.cadastrarPresente(
      nomePresente: nomeController.text,
      descricao: descricaoController.text,
      valor: valorFormatter.getUnformattedValue().toDouble(),
      linkLoja: linkController.text,
      statusProduto: 'DISPONIVEL',
      eventoId: widget.eventoId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resposta['mensagem'])));

    nomeController.clear();
    descricaoController.clear();
    valorController.clear();
    linkController.clear();

    await carregarPresentes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presentes')),

      body: PageContainer(
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Presente'),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: valorController,

              keyboardType: TextInputType.number,

              inputFormatters: [valorFormatter],

              decoration: const InputDecoration(labelText: 'Valor'),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: linkController,
              decoration: const InputDecoration(labelText: 'Link da Loja'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: adicionarPresente,
              child: const Text('Adicionar Presente'),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: presentes.length,

                itemBuilder: (context, index) {
                  final presente = presentes[index];

                  return Card(
                    child: ListTile(
                      title: Text(presente['nome_presente']),

                      subtitle: Text('R\$ ${presente['valor']}'),

                      trailing: Text(presente['status_produto']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
