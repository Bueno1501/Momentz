import 'package:flutter/material.dart';

class EventoConvidadoScreen extends StatelessWidget {
  final Map<String, dynamic> evento;

  const EventoConvidadoScreen({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Evento')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              evento['tipo_evento'] ?? 'Evento',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Informações do evento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text('Código: ${evento['codigo_evento']}'),

                    const SizedBox(height: 10),

                    Text('Data: ${evento['data_evento']}'),

                    const SizedBox(height: 10),

                    Text('Local: ${evento['local_evento']}'),

                    const SizedBox(height: 10),

                    Text('Cidade: ${evento['cidade_evento']}'),

                    const SizedBox(height: 10),

                    Text('Estado: ${evento['estado_evento']}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'O que você deseja fazer?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {
                  // Vamos implementar depois
                },

                icon: const Icon(Icons.photo_camera),

                label: const Text(
                  'Enviar foto',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {
                  // Vamos implementar depois
                },

                icon: const Icon(Icons.photo_library),

                label: const Text('Galeria', style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {
                  // Vamos implementar depois
                },

                icon: const Icon(Icons.check_circle),

                label: const Text(
                  'Confirmar presença',
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
