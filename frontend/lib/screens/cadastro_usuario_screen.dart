import 'package:flutter/material.dart';
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

  bool confirmarTemNumero = false;
  bool confirmarTemMaiuscula = false;
  bool confirmarTemEspecial = false;
  bool confirmarTemTamanho = false;

  bool mostrarSenha = false;
  bool mostrarConfirmarSenha = false;
  bool cadastrando = false;

  static const Color rosa = Color(0xFFE83ACB);
  static const Color rosaClaro = Color(0xFFECA0F2);
  static const Color roxoEscuro = Color(0xFF160020);

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  void validarSenha(String senha) {
    setState(() {
      temNumero = RegExp(r'[0-9]').hasMatch(senha);
      temMaiuscula = RegExp(r'[A-Z]').hasMatch(senha);
      temEspecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(senha);
      temTamanho = senha.length >= 8;
    });
  }

  void validarConfirmarSenha(String senha) {
    setState(() {
      confirmarTemNumero = RegExp(r'[0-9]').hasMatch(senha);
      confirmarTemMaiuscula = RegExp(r'[A-Z]').hasMatch(senha);
      confirmarTemEspecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(senha);
      confirmarTemTamanho = senha.length >= 8;
    });
  }

  Widget requisitoSenha(String texto, bool valido) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            valido ? Icons.check_circle : Icons.radio_button_unchecked,
            color: valido ? Colors.greenAccent : rosaClaro,
            size: 19,
          ),
          const SizedBox(width: 10),
          Text(
            texto,
            style: TextStyle(
              color: valido ? Colors.greenAccent : Colors.white,
              fontSize: 14,
              decoration: valido
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration decoracaoCampo({
    required String hint,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: rosaClaro, fontSize: 17),
      prefixIcon: Icon(icone, color: Colors.white, size: 27),
      suffixIcon: sufixo,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: rosaClaro, width: 1.7),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: rosa, width: 2),
      ),
    );
  }

  Future cancelarCadastro() async {
    final cancelar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar cadastro'),
        content: const Text('Realmente deseja cancelar o cadastro?'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text(
              'Continuar',
              style: TextStyle(color: Color(0xFF49105F)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: rosa,
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 40),
            ),
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
    if (cadastrando) return;

    FocusScope.of(context).unfocus();

    if (nomeController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        senhaController.text.isEmpty ||
        confirmarSenhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

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
            'A senha deve conter no mínimo 8 caracteres, '
            'letra maiúscula, minúscula, número e caractere especial.',
          ),
        ),
      );
      return;
    }

    setState(() {
      cadastrando = true;
    });

    try {
      final resposta = await ApiService.cadastrarUsuario(
        nome: nomeController.text.trim(),
        email: emailController.text.trim(),
        senha: senhaController.text,
        tipoUsuario: 'Administrador',
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cadastro realizado!'),
          content: Text(
            resposta['mensagem']?.toString() ??
                'Sua conta foi criada com sucesso. Faça login para continuar.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Ir para o login'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível realizar o cadastro.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cadastrando = false;
        });
      }
    }
  }

  Widget campoTexto({
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    TextInputType teclado = TextInputType.text,
    Widget? sufixo,
    bool ocultar = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      obscureText: ocultar,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 17),
      decoration: decoracaoCampo(hint: hint, icone: icone, sufixo: sufixo),
    );
  }

  Widget botaoCriarConta() {
    return SizedBox(
      height: 65,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE72DBB), Color(0xFFAE00B9)],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: ElevatedButton(
          onPressed: cadastrando ? null : cadastrarUsuario,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            minimumSize: const Size(0, 65),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: cadastrando
              ? const CircularProgressIndicator(color: Colors.white)
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 25,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Criar conta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoEscuro,
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: roxoEscuro);
                      },
                    ),

                    Container(color: Colors.black.withValues(alpha: 0.08)),

                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, innerConstraints) {
                          final double altura = innerConstraints.maxHeight;
                          final double espaco = altura < 750 ? 13 : 22;

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: altura),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWeb ? 65 : 28,
                                  vertical: 18,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Botão voltar
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.10,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: rosaClaro.withValues(
                                              alpha: 0.45,
                                            ),
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: cancelarCadastro,
                                          icon: const Icon(
                                            Icons.arrow_back_rounded,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: espaco),

                                    // Logo MOMENTZ
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
                                      width: 210,
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

                                    SizedBox(height: espaco + 10),

                                    const Text(
                                      'Cadastro de Administrador',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    const Text(
                                      'Crie sua conta para gerenciar seus eventos.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),

                                    SizedBox(height: espaco + 10),

                                    campoTexto(
                                      controller: nomeController,
                                      hint: 'Nome',
                                      icone: Icons.person,
                                    ),

                                    const SizedBox(height: 17),

                                    campoTexto(
                                      controller: emailController,
                                      hint: 'E-mail',
                                      icone: Icons.mail_outline,
                                      teclado: TextInputType.emailAddress,
                                    ),

                                    const SizedBox(height: 17),

                                    campoTexto(
                                      controller: senhaController,
                                      hint: 'Senha',
                                      icone: Icons.lock_outline,
                                      ocultar: !mostrarSenha,
                                      onChanged: validarSenha,
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

                                    const SizedBox(height: 12),

                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          requisitoSenha(
                                            'Pelo menos 8 caracteres',
                                            temTamanho,
                                          ),
                                          requisitoSenha(
                                            'Pelo menos 1 número',
                                            temNumero,
                                          ),
                                          requisitoSenha(
                                            'Pelo menos 1 letra maiúscula',
                                            temMaiuscula,
                                          ),
                                          requisitoSenha(
                                            'Pelo menos 1 caractere especial',
                                            temEspecial,
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 17),

                                    campoTexto(
                                      controller: confirmarSenhaController,
                                      hint: 'Confirmar Senha',
                                      icone: Icons.lock_outline,
                                      ocultar: !mostrarConfirmarSenha,
                                      onChanged: validarConfirmarSenha,
                                      sufixo: IconButton(
                                        icon: Icon(
                                          mostrarConfirmarSenha
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            mostrarConfirmarSenha =
                                                !mostrarConfirmarSenha;
                                          });
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          requisitoSenha(
                                            'Pelo menos 8 caracteres',
                                            confirmarTemTamanho,
                                          ),
                                          requisitoSenha(
                                            'Pelo menos 1 número',
                                            confirmarTemNumero,
                                          ),
                                          requisitoSenha(
                                            'Pelo menos 1 letra maiúscula',
                                            confirmarTemMaiuscula,
                                          ),
                                          requisitoSenha(
                                            'Pelo menos 1 caractere especial',
                                            confirmarTemEspecial,
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: espaco + 15),

                                    // Botões
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 65,
                                            child: OutlinedButton(
                                              onPressed: cancelarCadastro,
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                side: const BorderSide(
                                                  color: rosaClaro,
                                                  width: 1.8,
                                                ),
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.05),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                ),
                                              ),
                                              child: const Text(
                                                'Cancelar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 15),

                                        Expanded(child: botaoCriarConta()),
                                      ],
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
