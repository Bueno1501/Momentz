import 'dart:convert';
import '../services/api_service.dart';

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    buscarConvite();
  }

  Future<void> buscarConvite() async {
    try {
      final resposta = await http.get(
        Uri.parse('${ApiService.baseUrl}/convidados/convite/${widget.token}'),
      );

      final dados = jsonDecode(resposta.body);

      if (resposta.statusCode == 200) {
        setState(() {
          convite = dados['convite'];
          carregando = false;
        });
      } else {
        setState(() {
          erro = dados['erro'] ?? 'Convite inválido';
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        erro = 'Não foi possível acessar o convite.';
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (erro != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Convite')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              erro!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Convite')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            const Icon(Icons.mail_outline, size: 80),

            const SizedBox(height: 25),

            const Text(
              'Você está convidado!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Text(
              'Olá, ${convite!['nome']}!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 30),

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

                    const SizedBox(height: 20),

                    Text('Evento: ${convite!['tipo_evento']}'),

                    const SizedBox(height: 12),

                    Text('Data: ${convite!['data_evento']}'),

                    const SizedBox(height: 12),

                    Text('Local: ${convite!['local_evento']}'),

                    const SizedBox(height: 12),

                    Text(
                      'Cidade: ${convite!['cidade_evento']} - '
                      '${convite!['estado_evento']}',
                    ),

                    const SizedBox(height: 12),

                    Text('Código do evento: ${convite!['codigo_evento']}'),

                    if (convite!['descricao'] != null &&
                        convite!['descricao'].toString().isNotEmpty) ...[
                      const SizedBox(height: 20),

                      const Text(
                        'Mensagem',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(convite!['descricao'].toString()),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Deseja participar deste evento?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text(
                  'Confirmar presença',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text(
                  'Recusar convite',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
