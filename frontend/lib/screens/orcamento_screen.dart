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

  @override
  void dispose() {
    orcamentoController.dispose();
    super.dispose();
  }

  Future carregarOrcamento() async {
    final resultado = await ApiService.buscarOrcamento(widget.eventoId);

    if (!mounted) return;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Alterar orçamento',
          style: TextStyle(
            color: Color(0xFF350B42),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: editarController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Novo orçamento',
            hintText: 'Ex: 1500.00',
            prefixIcon: const Icon(
              Icons.attach_money,
              color: Color(0xFFC019C9),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC019C9), width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF350B42)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC019C9),
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (salvar != true) {
      editarController.dispose();
      return;
    }

    double novoValor;

    try {
      novoValor = double.parse(
        editarController.text.replaceAll(',', '.').trim(),
      );
    } catch (_) {
      editarController.dispose();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um valor válido.')));

      return;
    }

    editarController.dispose();

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
      return const Scaffold(
        backgroundColor: Color(0xFF21002E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF21002E),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD000C8), Color(0xFF8700A8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.monetization_on_outlined, size: 30),
            SizedBox(width: 12),
            Text(
              'Orçamento',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
            ),
          ],
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool desktop = constraints.maxWidth >= 700;

                if (desktop) {
                  return Container(
                    color: const Color(0xFF21002E),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/fundo_orcamento.png',
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  );
                }

                return Image.asset(
                  'assets/images/fundo_orcamento.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                );
              },
            ),
          ),

          Positioned.fill(
            child: Container(
              color: const Color(0xFF260033).withValues(alpha: 0.35),
            ),
          ),

          SafeArea(
            child: PageContainer(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),

                child: Column(
                  children: [
                    Card(
                      elevation: 8,
                      color: const Color(0xFFFFFBFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25),

                        child: Column(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              size: 70,
                              color: Color(0xFFD000C8),
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              'Orçamento Total',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF350B42),
                              ),
                            ),

                            const SizedBox(height: 10),

                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatoMoeda.format(orcamento),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF570B68),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Card(
                      elevation: 6,
                      color: const Color(0xFFFFFBFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),

                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Orçamento utilizado',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF350B42),
                                    ),
                                  ),
                                ),

                                Text(
                                  '${(percentual * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF850B91),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            LinearProgressIndicator(
                              value: percentual.clamp(0.0, 1.0),
                              minHeight: 13,
                              backgroundColor: const Color(0xFFEBD1F2),
                              borderRadius: BorderRadius.circular(10),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentual < 0.7
                                    ? Colors.green
                                    : percentual < 0.9
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${formatoMoeda.format(gasto)} de ${formatoMoeda.format(orcamento)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF570B68),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 6,
                            color: const Color(0xFFFFFBFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
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
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF350B42),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      formatoMoeda.format(gasto),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Card(
                            elevation: 6,
                            color: const Color(0xFFFFFBFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
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
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF350B42),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      formatoMoeda.format(saldo),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
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
                        label: const Text(
                          'Alterar orçamento',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC019C9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
