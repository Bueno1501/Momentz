import 'package:flutter/material.dart';
import 'package:frontend/widgets/page_container.dart';
import 'fornecedores_screen.dart';
import 'galeria_screen.dart';
import 'orcamento_screen.dart';

class GerenciarEventoScreen extends StatelessWidget {
  final int eventoId;

  const GerenciarEventoScreen({super.key, required this.eventoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Evento')),

      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FornecedoresScreen(eventoId: eventoId),
                  ),
                );
              },
              child: const Text('Fornecedores'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GaleriaScreen(eventoId: eventoId),
                  ),
                );
              },
              child: const Text('Galeria'),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrcamentoScreen(eventoId: eventoId),
                  ),
                );
              },
              child: const Text('Orçamento'),
            ),
          ],
        ),
      ),
    );
  }
}
