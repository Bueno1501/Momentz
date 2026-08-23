import 'package:flutter/material.dart';
import 'package:frontend/widgets/page_container.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool temNumero = false;
  bool temMaiuscula = false;
  bool temEspecial = false;
  bool temTamanho = false;

  bool mostrarSenha = false;
  bool mostrarConfirmarSenha = false;

  String tipoUsuario = 'Convidado';

  void validarSenha(String senha) {
    setState(() {
      temNumero = RegExp(r'[0-9]').hasMatch(senha);
      temMaiuscula = RegExp(r'[A-Z]').hasMatch(senha);
      temEspecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(senha);
      temTamanho = senha.length >= 8;
    });
  }

  Widget requisitoSenha(String texto, bool valido) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),

      child: Row(
        children: [
          Icon(
            valido ? Icons.check_circle : Icons.radio_button_unchecked,

            color: valido ? Colors.green : Colors.grey,
            size: 18,
          ),

          const SizedBox(width: 8),

          Text(
            texto,

            style: TextStyle(
              color: valido ? Colors.green : Colors.grey,

              decoration: valido
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Future cancelarCadastro() async {
    final cancelar = await showDialog<bool>(
      context: context,

      builder: (context) => AlertDialog(
        title: const Text('Cancelar cadastro'),

        content: const Text('Realmente deseja cancelar o cadstro ? '),

        actionsAlignment: MainAxisAlignment.center,

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('continuar'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),

            onPressed: () {
              Navigator.pop(context, true);
            },

            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (cancelar == true) {
      nomeController.clear();
      emailController.clear();
      senhaController.clear();
      confirmarSenhaController.clear();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future cadastrarUsuario() async {
    if (senhaController.text != confirmarSenhaController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('As senhas não coincidem.')));

      return;
    }

    final senhaRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#]).{8,}$',
    );

    if (!senhaRegex.hasMatch(senhaController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A senha deve conter no mínimo 8 caracteres, letra maiúscula, minúscula, número e caractere especial.',
          ),
        ),
      );

      return;
    }

    final resposta = await ApiService.cadastrarUsuario(
      nome: nomeController.text,
      email: emailController.text,
      senha: senhaController.text,
      tipoUsuario: tipoUsuario,
    );
    print(resposta);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sucesso'),
        content: Text(resposta['mensagem']),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Usuário'),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),

          onPressed: cancelarCadastro,
        ),
      ),

      body: PageContainer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,

                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: senhaController,

                onChanged: validarSenha,

                obscureText: !mostrarSenha,

                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),

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

              const SizedBox(height: 10),

              TextField(
                controller: confirmarSenhaController,

                obscureText: !mostrarConfirmarSenha,

                decoration: InputDecoration(
                  labelText: 'Confirmar Senha',
                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    icon: Icon(
                      mostrarConfirmarSenha
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        mostrarConfirmarSenha = !mostrarConfirmarSenha;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    requisitoSenha('Pelo menos 8 caracteres', temTamanho),
                    requisitoSenha('Pelo menos 1 número', temNumero),

                    requisitoSenha(
                      'Pelo menos 1 letra Maiúscula',
                      temMaiuscula,
                    ),

                    requisitoSenha(
                      'Pelo menos 1 caractere especial',
                      temEspecial,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: tipoUsuario,

                items: const [
                  DropdownMenuItem(
                    value: 'Administrador',
                    child: Text('Administrador'),
                  ),

                  DropdownMenuItem(
                    value: 'Convidado',
                    child: Text('Convidado'),
                  ),
                ],

                onChanged: (value) {
                  setState(() {
                    tipoUsuario = value!;
                  });
                },

                decoration: const InputDecoration(labelText: 'Tipo de Usuário'),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: cancelarCadastro,

                      child: const Text('Cancelar'),
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: cadastrarUsuario,

                      child: const Text('Cadastrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
