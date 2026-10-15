import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;

class ConviteScreen extends StatefulWidget {
  final String token;

  const ConviteScreen({super.key, required this.token});

  @override
  State<ConviteScreen> createState() => _ConviteScreenState();
}

class _ConviteScreenState extends State<ConviteScreen> {
  Map<String, dynamic>? convite;
  bool carregando = true;
  String? erro;

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final acompanhantesController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    buscarEvento();
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    acompanhantesController.dispose();
    super.dispose();
  }

  Future<void> buscarEvento() async {
    try {
      final resposta = await http.get(
        Uri.parse('${ApiService.baseUrl}/eventos/convite/${widget.token}'),
      );

      final dados = jsonDecode(resposta.body);

      if (!mounted) return;

      if (resposta.statusCode == 200) {
        setState(() {
          convite = Map<String, dynamic>.from(dados['evento']);
          carregando = false;
        });
      } else {
        setState(() {
          erro = dados['erro'] ?? 'Convite inválido';
          carregando = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        erro = 'Não foi possível acessar o convite.';
        carregando = false;
      });
    }
  }

  String valor(String campo, [String padrao = 'Não informado']) {
    final dado = convite?[campo];
    if (dado == null || dado.toString().trim().isEmpty) {
      return padrao;
    }
    return dado.toString();
  }

  String formatarData(dynamic data) {
    if (data == null) return 'Não informada';

    final texto = data.toString();
    final dataLocal = DateTime.tryParse(texto);

    if (dataLocal == null) return texto;

    return '${dataLocal.day.toString().padLeft(2, '0')}/'
        '${dataLocal.month.toString().padLeft(2, '0')}/'
        '${dataLocal.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (erro != null || convite == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Convite')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              erro ?? 'Não foi possível carregar o convite.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    final urlConvite = convite!['convite_url']?.toString();
    final urlCompleta = urlConvite == null || urlConvite.isEmpty
        ? null
        : Uri.parse(ApiService.baseUrl).resolve(urlConvite).toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Convite')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                if (urlCompleta != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Convite do evento',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Image.network(
                            urlCompleta,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Não foi possível carregar a imagem do convite.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.mail_outline, size: 72),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 20),

                Text(
                  'Você está convidado!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Venha participar do nosso ${valor('tipo_evento', 'evento')}!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informações do evento',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _informacao(
                          Icons.celebration,
                          'Evento',
                          valor('tipo_evento'),
                        ),
                        _informacao(
                          Icons.calendar_month,
                          'Data',
                          formatarData(convite!['data_evento']),
                        ),
                        _informacao(
                          Icons.location_on,
                          'Local',
                          valor('local_evento'),
                        ),
                        _informacao(
                          Icons.location_city,
                          'Cidade',
                          '${valor('cidade_evento')} - '
                              '${valor('estado_evento')}',
                        ),
                        if (valor('descricao', '').isNotEmpty)
                          _informacao(
                            Icons.message_outlined,
                            'Mensagem',
                            valor('descricao'),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Confirme sua presença',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Preencha seus dados para responder ao convite.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: nomeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: telefoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: acompanhantesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de acompanhantes',
                    helperText: 'Informe 0 se você não levar acompanhantes.',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _mostrarAviso(
                            'A confirmação será habilitada na próxima etapa.',
                          ),
                          child: const Text(
                            'Confirmar presença',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => _mostrarAviso(
                            'A recusa será habilitada na próxima etapa.',
                          ),
                          child: const Text(
                            'Recusar convite',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _informacao(IconData icone, String titulo, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$titulo: $texto',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }
}
