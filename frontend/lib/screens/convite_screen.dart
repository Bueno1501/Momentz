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
  final criancas03Controller = TextEditingController(text: '0');
  final criancas47Controller = TextEditingController(text: '0');
  final acompanhantes8Controller = TextEditingController(text: '0');

  bool enviando = false;
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
    criancas03Controller.dispose();
    criancas47Controller.dispose();
    acompanhantes8Controller.dispose();

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

  Future<void> _responderConvite(String status) async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final telefone = telefoneController.text.trim();

    if (nome.isEmpty || email.isEmpty || telefone.isEmpty) {
      _mostrarAviso('Preencha nome, e-mail e telefone.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _mostrarAviso('Informe um e-mail válido.');
      return;
    }

    final criancas03 = int.tryParse(criancas03Controller.text);
    final criancas47 = int.tryParse(criancas47Controller.text);
    final acompanhantes8 = int.tryParse(acompanhantes8Controller.text);

    if (criancas03 == null ||
        criancas47 == null ||
        acompanhantes8 == null ||
        criancas03 < 0 ||
        criancas47 < 0 ||
        acompanhantes8 < 0) {
      _mostrarAviso('Informe quantidades inteiras iguais ou maiores que zero.');
      return;
    }

    setState(() => enviando = true);

    try {
      final resposta = await http.post(
        Uri.parse('${ApiService.baseUrl}/eventos/publico/${widget.token}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nome,
          'email': email,
          'telefone': telefone,
          'criancas_0_3': criancas03,
          'criancas_4_7': criancas47,
          'acompanhantes_8_mais': acompanhantes8,
          'status_confirmacao': status,
        }),
      );

      final dados = jsonDecode(resposta.body);

      if (!mounted) return;

      if (resposta.statusCode == 201) {
        _mostrarAviso(
          status == 'CONFIRMADO'
              ? 'Presença confirmada com sucesso!'
              : 'Recusa registrada com sucesso.',
        );
      } else {
        _mostrarAviso(
          dados['erro']?.toString() ?? 'Não foi possível registrar a resposta.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarAviso('Erro de conexão com o servidor.');
    } finally {
      if (mounted) {
        setState(() => enviando = false);
      }
    }
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
        : (urlConvite.startsWith('http://') ||
              urlConvite.startsWith('https://'))
        ? urlConvite
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convite'),
        backgroundColor: const Color(0xFF2B1745),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fundo_convite.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF180824).withValues(alpha: 0.65),
            ),
          ),
          SingleChildScrollView(
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
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
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
                      controller: criancas03Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Crianças de 0 a 3 anos',
                        helperText:
                            'Quantidade de crianças nessa faixa etária.',
                        prefixIcon: Icon(Icons.child_care),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: criancas47Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Crianças de 4 a 7 anos',
                        helperText:
                            'Quantidade de crianças nessa faixa etária.',
                        prefixIcon: Icon(Icons.child_care),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: acompanhantes8Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Acompanhantes de 8 anos ou mais',
                        helperText:
                            'Inclua aqui os acompanhantes com 8 anos ou mais.',
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
                              onPressed: enviando
                                  ? null
                                  : () => _responderConvite('CONFIRMADO'),
                              child: enviando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
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
                              onPressed: enviando
                                  ? null
                                  : () => _responderConvite('RECUSADO'),
                              child: enviando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
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
        ],
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
