import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/page_container.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

class FornecedoresScreen extends StatefulWidget {
  final int eventoId;

  const FornecedoresScreen({super.key, required this.eventoId});

  @override
  State<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends State<FornecedoresScreen> {
  final nomeController = TextEditingController();
  final categoriaController = TextEditingController();
  final telefoneController = TextEditingController();
  final emailController = TextEditingController();
  final valorController = TextEditingController();
  final observacaoController = TextEditingController();

  String? erroNome;
  String? erroCategoria;
  String? erroTelefone;
  String? erroEmail;
  String? erroValor;

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final valorFormatter = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    decimalDigits: 2,
    symbol: 'R\$',
  );

  List fornecedores = [];
  @override
  void initState() {
    super.initState();
    carregarFornecedores();
  }

  Future carregarFornecedores() async {
    final lista = await ApiService.buscarFornecedores(widget.eventoId);

    setState(() {
      fornecedores = lista;
    });
  }

  Future adicionarFornecedor() async {
    setState(() {
      erroNome = null;
      erroCategoria = null;
      erroTelefone = null;
      erroEmail = null;
      erroValor = null;
    });

    setState(() {
      erroNome = nomeController.text.trim().isEmpty ? 'Informe o nome' : null;

      erroCategoria = categoriaController.text.trim().isEmpty
          ? 'informe a categoria'
          : null;

      erroTelefone = telefoneController.text.trim().isEmpty
          ? 'Informe o telefone'
          : null;

      erroEmail = emailController.text.trim().isEmpty
          ? 'Informe o email'
          : null;

      erroValor = valorController.text.trim().isEmpty
          ? 'Informe o valor'
          : null;
    });

    if (erroNome != null ||
        erroCategoria != null ||
        erroTelefone != null ||
        erroEmail != null ||
        erroValor != null) {
      return;
    }

    if (nomeController.text.trim().isEmpty ||
        categoriaController.text.trim().isEmpty ||
        telefoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        valorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
    }

    if (telefoneMask.getUnmaskedText().length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um telefone válido')),
      );

      return;
    }
    final resposta = await ApiService.cadastrarFornecedor(
      nome: nomeController.text,
      categoria: categoriaController.text,
      telefone: telefoneController.text,
      email: emailController.text,
      valor: valorFormatter.getUnformattedValue().toDouble(),
      observacao: observacaoController.text,
      statusFornecedor: 'CONTRATADO',
      eventoId: widget.eventoId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resposta['mensagem'])));

    nomeController.clear();
    categoriaController.clear();
    telefoneController.clear();
    emailController.clear();
    valorController.clear();
    observacaoController.clear();

    await carregarFornecedores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fornecedores')),

      body: PageContainer(
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome',
                errorText: erroNome,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: categoriaController,
              decoration: InputDecoration(
                labelText: 'Categoria',
                errorText: erroCategoria,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: telefoneController,

              keyboardType: TextInputType.number,

              maxLength: 15,

              inputFormatters: [telefoneMask],

              decoration: InputDecoration(
                labelText: 'Telefone',
                counterText: '',
                errorText: erroTelefone,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: erroEmail,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: valorController,

              keyboardType: TextInputType.number,
              inputFormatters: [valorFormatter],
              decoration: InputDecoration(
                labelText: 'Valor',
                errorText: erroValor,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: observacaoController,
              decoration: const InputDecoration(labelText: 'Observação'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: adicionarFornecedor,
              child: const Text('Adicionar Forncedor!'),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: fornecedores.length,

                itemBuilder: (context, index) {
                  final fornecedor = fornecedores[index];

                  return Card(
                    child: ListTile(
                      title: Text(fornecedor['nome']),

                      subtitle: Text(
                        '${fornecedor['categoria']} - R\$ ${fornecedor['valor']}',
                      ),
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
