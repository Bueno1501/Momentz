// ignore: unused_import
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/page_container.dart';
import 'cadastro_usuario_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool mostrarSenha = false;

  String? erroEmail;
  String? erroSenha;

  @override
  void initState() {
    super.initState();

    emailController.clear();
    senhaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Momentz')),

      body: PageContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem Vindo ao Momentz',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),

                errorText: erroEmail,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: senhaController,

              obscureText: !mostrarSenha,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),

                errorText: erroSenha,

                suffixIcon: IconButton(
                  icon: Icon(
                    mostrarSenha ? Icons.visibility_off : Icons.visibility,
                  ),

                  onPressed: () {
                    setState(() {
                      mostrarSenha = !mostrarSenha;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    erroEmail = null;
                    erroSenha = null;
                  });

                  final resposta = await ApiService.login(
                    email: emailController.text,
                    senha: senhaController.text,
                  );

                  print(resposta);

                  if (!mounted) return;

                  if (resposta['usuario_id'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          usuarioId: resposta['usuario_id'],
                          nomeUsuario: resposta['nome'],
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      erroEmail = 'Email ou senha inválidos';
                      erroSenha = 'Email ou Senha inválidos';
                    });

                    emailController.clear();
                    senhaController.clear();
                  }
                },
                child: const Text('Entrar'),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CadastroUsuarioScreen(),
                  ),
                );
                // Navegar para cadastro
              },
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
