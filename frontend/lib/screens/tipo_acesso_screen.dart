import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'acesso_evento_screen.dart';

class TipoAcessoScreen extends StatelessWidget {
  const TipoAcessoScreen({super.key});

  static const Color roxoEscuro = Color(0xFF21002E);
  static const Color magenta = Color(0xFFD000C8);
  static const Color lilas = Color(0xFFECA0F2);

  Widget opcaoAcesso({
    required BuildContext context,
    required IconData icone,
    required String titulo,
    required String descricao,
    required bool administrador,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        gradient: administrador
            ? const LinearGradient(
                colors: [Color(0xFFE52BC6), Color(0xFFAD00B9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: administrador ? null : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(30),
        border: administrador ? null : Border.all(color: lilas, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Icon(icone, color: Colors.white, size: 55),

                const SizedBox(width: 22),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        descricao,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 27,
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
          final bool desktop = constraints.maxWidth >= 700;

          final double largura = desktop
              ? constraints.maxWidth.clamp(0.0, 700.0).toDouble()
              : constraints.maxWidth;

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: roxoEscuro,
            child: Center(
              child: SizedBox(
                width: largura,
                height: constraints.maxHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/fundo_login.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),

                    Container(color: roxoEscuro.withValues(alpha: 0.08)),

                    SafeArea(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 45 : 28,
                          vertical: 25,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 50,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFFE83ACB),
                                size: 85,
                              ),

                              const Text(
                                'Momentz',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              Container(
                                width: 210,
                                height: 5,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      magenta,
                                      Color(0xFFB000B5),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),

                              const SizedBox(height: 55),

                              // TÍTULO
                              const Text(
                                'Selecione o acesso',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 29,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 12),

                              const Text(
                                'Como você deseja entrar na plataforma?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFE8B7F3),
                                  fontSize: 17,
                                ),
                              ),

                              const SizedBox(height: 45),

                              opcaoAcesso(
                                context: context,
                                icone: Icons.verified_user_outlined,
                                titulo: 'Administrador',
                                descricao: 'Crie e gerencie seus eventos.',
                                administrador: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),

                              opcaoAcesso(
                                context: context,
                                icone: Icons.people_outline_rounded,
                                titulo: 'Convidado',
                                descricao: 'Acesse um evento criado.',
                                administrador: false,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AcessoEventoScreen(),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
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
