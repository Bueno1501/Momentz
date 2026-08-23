import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/page_container.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:intl/intl.dart';

class OrcamentoScreen extends StatefulWidget {
  final int eventoId;

  const OrcamentoScreen({super.key, required this.eventoId});

  @override
  State<OrcamentoScreen> createState() => _OrcamentoScreenState();
}

class _OrcamentoScreenState extends State<OrcamentoScreen> {
  Map<String, dynamic> dados = {};

  final orcamentoController = TextEditingController();

  final valorFormatter = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    decimalDigits: 2,
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    carregarOrcamento();
  }

  Future carregarOrcamento() async {
    final resultado = await ApiService.buscarOrcamento(widget.eventoId);

    setState(() {
      dados = resultado;

      if (dados.isNotEmpty) {
        orcamentoController.text = dados['orcamento_total'].toString();
      }
    });
  }

  Future alterarOrcamento() async {
    final editarController = TextEditingController(
      text: dados['orcamento_total'].toString(),
    );

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar orçamento'),

        content: TextField(
          controller: editarController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),

          decoration: const InputDecoration(
            labelText: 'Novo orçamento',
            hintText: 'Ex: 1500.00',
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),

            onPressed: () {
              Navigator.pop(context, true);
            },

            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (salvar != true) return;

    double novoValor;

    try {
      novoValor = double.parse(
        editarController.text.replaceAll(',', '.').trim(),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um valor válido.')));

      return;
    }

    await ApiService.atualizarOrcamento(
      eventoId: widget.eventoId,
      orcamento: novoValor,
    );

    await carregarOrcamento();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orçamento atualizado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double orcamento = (dados['orcamento_total'] ?? 0).toDouble();
    final double gasto = (dados['gasto'] ?? 0).toDouble();
    final double saldo = (dados['saldo'] ?? 0).toDouble();
    final double percentual = orcamento > 0 ? gasto / orcamento : 0;

    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (dados.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Orçamento')),

      body: PageContainer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 8,

                child: Padding(
                  padding: const EdgeInsets.all(25),

                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        size: 70,
                        color: Color(0xFFBB86FC),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Orçamento Total',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        formatoMoeda.format(orcamento),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              LinearProgressIndicator(
                value: percentual,
                minHeight: 12,
                backgroundColor: Colors.white12,
                borderRadius: BorderRadius.circular(10),

                valueColor: AlwaysStoppedAnimation<Color>(
                  percentual < 0.7
                      ? Colors.green
                      : percentual < 0.9
                      ? Colors.orange
                      : Colors.red,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '${(percentual * 100).toStringAsFixed(1)}% do orçamento utilizado',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),

                        child: Column(
                          children: [
                            const Icon(
                              Icons.trending_down,
                              color: Colors.red,
                              size: 35,
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Total Gasto',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              formatoMoeda.format(gasto),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),

                        child: Column(
                          children: [
                            const Icon(
                              Icons.savings,
                              color: Colors.green,
                              size: 35,
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Saldo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              formatoMoeda.format(saldo),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: alterarOrcamento,
                  icon: const Icon(Icons.edit),
                  label: const Text('Alterar orçamento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
