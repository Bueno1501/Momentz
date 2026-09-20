import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'acesso_evento_screen.dart';

class TipoAcessoScreen extends StatelessWidget {
  const TipoAcessoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'MOMENTZ',
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Selecione o acesso !!',
                  style: TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 45),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },

                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text(
                      'Administrador',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AcessoEventoScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.people),
                    label: const Text(
                      'Convidado',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
