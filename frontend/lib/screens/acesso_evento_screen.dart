import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'evento_convidado_screen.dart';

class AcessoEventoScreen extends StatefulWidget {
  const AcessoEventoScreen({super.key});

  @override
  State<AcessoEventoScreen> createState() => _AcessoEventoScreenState();
}

class _AcessoEventoScreenState extends State<AcessoEventoScreen> {
  final TextEditingController codigoController = TextEditingController();

  bool carregando = false;

  static const Color roxo = Color(0xFF26002F);
  static const Color magenta = Color(0xFFE500C8);
  static const Color lilas = Color(0xFFE7A3F7);

  Future<Map<String, String>?> solicitarIdentificacao() async {
    final nomeController = TextEditingController();
    final emailController = TextEditingController();

    try {
      return await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF31003D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Identificação',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Informe seu nome e e-mail para receber o código de confirmação.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nomeController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome completo',
                      labelStyle: const TextStyle(color: lilas),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: lilas,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: lilas),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: magenta),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      labelStyle: const TextStyle(color: lilas),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: lilas,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: lilas),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: magenta),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: magenta,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final nome = nomeController.text.trim();
                  final email = emailController.text.trim();

                  if (nome.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Informe seu nome completo.'),
                      ),
                    );
                    return;
                  }

                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Informe um e-mail válido.'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, {'nome': nome, 'email': email});
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      );
    } finally {
      nomeController.dispose();
      emailController.dispose();
    }
  }

  Future<String?> solicitarCodigoVerificacao() async {
    final codigoVerificacaoController = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF31003D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Confirmar e-mail',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    color: magenta,
                    size: 55,
                  ),
                  const SizedBox(height: 15),

                  const Text(
                    'Enviamos um código de seis dígitos para seu e-mail. Digite-o abaixo para acessar o evento.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: codigoVerificacaoController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      letterSpacing: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: lilas),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: magenta),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: magenta,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final codigo = codigoVerificacaoController.text.trim();

                  if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Digite os seis dígitos do código.'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, codigo);
                },
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );
    } finally {
      codigoVerificacaoController.dispose();
    }
  }

  Future<void> acessarEvento() async {
    final codigo = codigoController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o código do evento.')),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      final response = await http.post(
        Uri.parse('https://momentz-production.up.railway.app/eventos/acessar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'codigo_evento': codigo}),
      );

      final dados = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception(dados['erro'] ?? 'Não foi possível acessar o evento.');
      }

      final evento = Map<String, dynamic>.from(dados['evento']);

      final identificacao = await solicitarIdentificacao();

      if (!mounted || identificacao == null) return;

      await ApiService.enviarCodigoConvidado(
        codigoEvento: codigo,
        nome: identificacao['nome']!,
        email: identificacao['email']!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código enviado para seu e-mail!'),
          backgroundColor: Colors.green,
        ),
      );

      final codigoVerificacao = await solicitarCodigoVerificacao();

      if (!mounted || codigoVerificacao == null) return;

      await ApiService.validarCodigoConvidado(
        codigoEvento: codigo,
        email: identificacao['email']!,
        codigo: codigoVerificacao,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EventoConvidadoScreen(evento: evento),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );

      debugPrint('Erro na autenticação do convidado: $erro');
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  Widget construirLogo({required bool desktop}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.photo_camera_outlined,
          size: desktop ? 76 : 52,
          color: Colors.white,
        ),

        const SizedBox(height: 2),

        Text(
          'Momentz',
          style: TextStyle(
            fontSize: desktop ? 43 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1.5,
          ),
        ),

        Container(
          width: desktop ? 150 : 115,
          height: 4,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: magenta,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  Widget construirCampoCodigo() {
    return TextField(
      controller: codigoController,
      enabled: !carregando,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        hintText: 'Código do evento',
        hintStyle: const TextStyle(color: Color(0xFFD9B9E6), fontSize: 17),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Icon(Icons.qr_code_2, color: Colors.white, size: 30),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 65),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 19,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: lilas, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: magenta, width: 2.5),
        ),
      ),
      onSubmitted: (_) => acessarEvento(),
    );
  }

  Widget construirBotao({required bool desktop}) {
    return SizedBox(
      width: double.infinity,
      height: desktop ? 64 : 56,
      child: ElevatedButton(
        onPressed: carregando ? null : acessarEvento,
        style: ElevatedButton.styleFrom(
          backgroundColor: magenta,
          disabledBackgroundColor: magenta.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: magenta.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: carregando
            ? const SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: desktop ? 29 : 25),

                  const SizedBox(width: 15),

                  Text(
                    'Entrar no evento',
                    style: TextStyle(
                      fontSize: desktop ? 19 : 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxo,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final largura = constraints.maxWidth;
          final altura = constraints.maxHeight;

          final desktop = largura >= 700;

          final mobileCompacto = !desktop && altura < 700;

          final imagemFundo = desktop
              ? 'assets/images/fundo_acesso_evento_desktop.png'
              : 'assets/images/fundo_acesso_evento_mobile.png';

          final larguraConteudo = desktop ? 850.0 : largura * 0.88;

          return Stack(
            fit: StackFit.expand,
            children: [
              // FUNDO RESPONSIVO
              Positioned.fill(
                child: Image.asset(
                  imagemFundo,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Erro ao carregar fundo: $error');
                    return Container(color: roxo);
                  },
                ),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        roxo.withValues(alpha: 0.08),
                        roxo.withValues(alpha: 0.18),
                        roxo.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
              ),

              // BOTÃO VOLTAR
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.all(desktop ? 18 : 12),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 30,
                        ),
                        tooltip: 'Voltar',
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: desktop ? 35 : 20,
                      vertical: mobileCompacto ? 8 : 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: larguraConteudo),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: desktop ? 15 : 5),

                          construirLogo(desktop: desktop),

                          SizedBox(
                            height: desktop
                                ? 55
                                : mobileCompacto
                                ? 16
                                : 25,
                          ),

                          Icon(
                            Icons.confirmation_number_outlined,
                            size: desktop ? 88 : 62,
                            color: Colors.white,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Acessar evento',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: desktop ? 46 : 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: desktop ? 14 : 10),

                          Text(
                            'Digite o código do evento para continuar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: desktop ? 21 : 15,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(
                            height: desktop
                                ? 42
                                : mobileCompacto
                                ? 16
                                : 25,
                          ),

                          construirCampoCodigo(),

                          SizedBox(height: desktop ? 25 : 18),

                          construirBotao(desktop: desktop),

                          SizedBox(height: desktop ? 20 : 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
