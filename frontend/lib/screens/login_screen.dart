import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
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
  bool carregando = false;

  String? erroEmail;
  String? erroSenha;

  static const Color rosa = Color(0xFFE83ACB);
  static const Color rosaClaro = Color(0xFFECA0F2);

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> realizarLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      erroEmail = null;
      erroSenha = null;
    });

    if (emailController.text.trim().isEmpty || senhaController.text.isEmpty) {
      setState(() {
        if (emailController.text.trim().isEmpty) {
          erroEmail = 'Informe seu e-mail';
        }

        if (senhaController.text.isEmpty) {
          erroSenha = 'Informe sua senha';
        }
      });
      return;
    }

    setState(() => carregando = true);

    try {
      final resposta = await ApiService.login(
        email: emailController.text.trim(),
        senha: senhaController.text,
      );

      if (!mounted) return;

      if (resposta['usuario_id'] != null && resposta['token'] != null) {
        ApiService.token = resposta['token'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              usuarioId: resposta['usuario_id'],
              nomeUsuario: resposta['nome'],
            ),
          ),
        );
      } else {
        setState(() {
          erroEmail = 'E-mail ou senha inválidos';
          erroSenha = 'E-mail ou senha inválidos';
        });

        emailController.clear();
        senhaController.clear();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível realizar o login. Verifique sua conexão.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  InputDecoration decoracaoCampo({
    required String hint,
    required IconData icone,
    Widget? sufixo,
    String? erro,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: rosaClaro, fontSize: 17),

      prefixIcon: Icon(icone, color: Colors.white, size: 27),

      suffixIcon: sufixo,
      errorText: erro,

      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),

      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 23),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: rosaClaro, width: 1.7),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: rosa, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF160020),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWeb = constraints.maxWidth >= 700;

          final double panelWidth = isWeb ? 460 : constraints.maxWidth;

          final double panelHeight = isWeb
              ? (constraints.maxHeight - 48).clamp(600.0, 900.0)
              : constraints.maxHeight;

          return Container(
            width: double.infinity,
            height: double.infinity,

            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF160020),
                  Color(0xFF30003D),
                  Color(0xFF160020),
                ],
              ),
            ),

            child: Center(
              child: Container(
                width: panelWidth,
                height: panelHeight,
                clipBehavior: Clip.antiAlias,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isWeb ? 18 : 0),

                  boxShadow: isWeb
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),

                child: Stack(
                  fit: StackFit.expand,

                  children: [
                    Image.asset(
                      'assets/images/fundo_login.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,

                      errorBuilder: (_, __, ___) {
                        return Container(color: const Color(0xFF21052F));
                      },
                    ),

                    Container(color: Colors.black.withValues(alpha: 0.08)),

                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, innerConstraints) {
                          final double altura = innerConstraints.maxHeight;

                          final double espaco = altura < 700 ? 16 : 28;

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),

                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: altura),

                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWeb ? 36 : 28,
                                  vertical: 20,
                                ),

                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 90,
                                      color: rosa,
                                    ),

                                    const Text(
                                      'Momentz',
                                      style: TextStyle(
                                        fontSize: 46,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),

                                    Container(
                                      width: 230,
                                      height: 5,

                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            rosa,
                                            Color(0xFFB000B5),
                                            Colors.transparent,
                                          ],
                                        ),

                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),

                                    SizedBox(height: espaco + 12),

                                    const Text(
                                      'Bem-Vindo ao Momentz',
                                      textAlign: TextAlign.center,

                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    const Text(
                                      'A plataforma completa para o seu evento.',
                                      textAlign: TextAlign.center,

                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),

                                    SizedBox(height: espaco + 12),

                                    // CAMPO E-MAIL
                                    TextField(
                                      controller: emailController,

                                      keyboardType: TextInputType.emailAddress,

                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                      ),

                                      decoration: decoracaoCampo(
                                        hint: 'E-mail',
                                        icone: Icons.mail_outline,
                                        erro: erroEmail,
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    TextField(
                                      controller: senhaController,

                                      obscureText: !mostrarSenha,

                                      onSubmitted: (_) => realizarLogin(),

                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                      ),

                                      decoration: decoracaoCampo(
                                        hint: 'Senha',
                                        icone: Icons.lock_outline,
                                        erro: erroSenha,

                                        sufixo: IconButton(
                                          icon: Icon(
                                            mostrarSenha
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,

                                            color: Colors.white,
                                          ),

                                          onPressed: () {
                                            setState(() {
                                              mostrarSenha = !mostrarSenha;
                                            });
                                          },
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: espaco),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 64,

                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFE72DBB),
                                              Color(0xFFAE00B9),
                                            ],
                                          ),

                                          borderRadius: BorderRadius.circular(
                                            27,
                                          ),
                                        ),

                                        child: ElevatedButton(
                                          onPressed: carregando
                                              ? null
                                              : realizarLogin,

                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,

                                            disabledBackgroundColor:
                                                Colors.transparent,

                                            shadowColor: Colors.transparent,

                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(27),
                                            ),
                                          ),

                                          child: carregando
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                              : const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,

                                                  children: [
                                                    Icon(
                                                      Icons.login,
                                                      size: 30,
                                                      color: Colors.white,
                                                    ),

                                                    SizedBox(width: 18),

                                                    Text(
                                                      'Entrar',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: espaco),

                                    // DIVISOR OU
                                    const Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: rosaClaro,
                                            thickness: 1.2,
                                          ),
                                        ),

                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),

                                          child: Text(
                                            'ou',

                                            style: TextStyle(
                                              color: rosaClaro,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),

                                        Expanded(
                                          child: Divider(
                                            color: rosaClaro,
                                            thickness: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: espaco),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 64,

                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CadastroUsuarioScreen(),
                                            ),
                                          );
                                        },

                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: rosaClaro,
                                            width: 1.8,
                                          ),

                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                          ),

                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.05),
                                        ),

                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,

                                          children: [
                                            Icon(
                                              Icons.person_add_alt_1,
                                              color: Colors.white,
                                              size: 30,
                                            ),

                                            SizedBox(width: 18),

                                            Text(
                                              'Criar conta',

                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 25),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
