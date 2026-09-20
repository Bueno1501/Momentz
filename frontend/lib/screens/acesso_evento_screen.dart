import 'dart:convert';

import 'evento_convidado_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AcessoEventoScreen extends StatefulWidget {
  const AcessoEventoScreen({super.key});

  @override
  State<AcessoEventoScreen> createState() => _AcessoEventoScreenState();
}

class _AcessoEventoScreenState extends State<AcessoEventoScreen> {
  final TextEditingController codigoController = TextEditingController();

  bool carregando = false;

  Future<void> acessarEvento() async {
    final codigo = codigoController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o código do evento')),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/eventos/acessar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'codigo_evento': codigo}),
      );

      final dados = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EventoConvidadoScreen(evento: dados['evento']),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dados['erro'] ?? 'Erro ao acessar evento')),
        );
      }
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível conectar ao servidor')),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acessar evento')),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 80),

              const SizedBox(height: 25),

              const Text(
                'Acessar evento',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                'Digite o código do evento para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: codigoController,
                textCapitalization: TextCapitalization.characters,

                decoration: const InputDecoration(
                  labelText: 'Código do evento',
                  hintText: 'Ex: EVE1234',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: carregando ? null : acessarEvento,

                  child: carregando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Text(
                          'Entrar no evento',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
