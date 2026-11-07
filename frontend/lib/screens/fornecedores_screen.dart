import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/page_container.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

class FornecedoresScreen extends StatefulWidget {
  final int eventoId;

  const FornecedoresScreen({super.key, required this.eventoId});

  @override
  State<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends State<FornecedoresScreen> {
  final nomeController = TextEditingController();
  final categoriaController = TextEditingController();
  final telefoneController = TextEditingController();
  final emailController = TextEditingController();
  final valorController = TextEditingController();
  final observacaoController = TextEditingController();

  String? erroNome;
  String? erroCategoria;
  String? erroTelefone;
  String? erroEmail;
  String? erroValor;

  bool carregando = false;
  bool cadastrando = false;

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final valorFormatter = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    decimalDigits: 2,
    symbol: 'R\$',
  );

  List fornecedores = [];

  static const Color roxoEscuro = Color(0xFF21002E);
  static const Color roxoMedio = Color(0xFF49105F);
  static const Color magenta = Color(0xFFD000C8);
  static const Color lilas = Color(0xFFF3DDF8);
  static const Color textoRoxo = Color(0xFF351044);

  @override
  void initState() {
    super.initState();
    carregarFornecedores();
  }

  @override
  void dispose() {
    nomeController.dispose();
    categoriaController.dispose();
    telefoneController.dispose();
    emailController.dispose();
    valorController.dispose();
    observacaoController.dispose();
    super.dispose();
  }

  Future carregarFornecedores() async {
    if (mounted) {
      setState(() {
        carregando = true;
      });
    }

    try {
      final lista = await ApiService.buscarFornecedores(widget.eventoId);

      if (!mounted) return;

      setState(() {
        fornecedores = lista;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar os fornecedores.'),
        ),
      );
    }
  }

  Future adicionarFornecedor() async {
    if (cadastrando) return;

    setState(() {
      erroNome = nomeController.text.trim().isEmpty
          ? 'Informe o nome do fornecedor'
          : null;

      erroCategoria = categoriaController.text.trim().isEmpty
          ? 'Informe a categoria'
          : null;

      erroTelefone = telefoneController.text.trim().isEmpty
          ? 'Informe o telefone'
          : null;

      erroEmail = emailController.text.trim().isEmpty
          ? 'Informe o e-mail'
          : null;

      erroValor = valorController.text.trim().isEmpty
          ? 'Informe o valor'
          : null;
    });

    if (erroNome != null ||
        erroCategoria != null ||
        erroTelefone != null ||
        erroEmail != null ||
        erroValor != null) {
      return;
    }

    if (telefoneMask.getUnmaskedText().length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um telefone válido.')),
      );
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (!emailRegex.hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um e-mail válido.')));
      return;
    }

    setState(() {
      cadastrando = true;
    });

    try {
      final resposta = await ApiService.cadastrarFornecedor(
        nome: nomeController.text.trim(),
        categoria: categoriaController.text.trim(),
        telefone: telefoneController.text,
        email: emailController.text.trim(),
        valor: valorFormatter.getUnformattedValue().toDouble(),
        observacao: observacaoController.text.trim(),
        statusFornecedor: 'CONTRATADO',
        eventoId: widget.eventoId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resposta['mensagem']?.toString() ??
                'Solicitação de cadastro finalizada.',
          ),
        ),
      );

      nomeController.clear();
      categoriaController.clear();
      telefoneController.clear();
      emailController.clear();
      valorController.clear();
      observacaoController.clear();

      await carregarFornecedores();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível cadastrar o fornecedor.'),
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

  IconData iconeCategoria(String? categoria) {
    final texto = (categoria ?? '').toString().toLowerCase();

    if (texto.contains('buffet') || texto.contains('comida')) {
      return Icons.restaurant_menu_rounded;
    }

    if (texto.contains('foto') || texto.contains('film')) {
      return Icons.camera_alt_rounded;
    }

    if (texto.contains('flor') || texto.contains('decora')) {
      return Icons.local_florist_rounded;
    }

    if (texto.contains('música') || texto.contains('musica')) {
      return Icons.music_note_rounded;
    }

    if (texto.contains('som') || texto.contains('dj')) {
      return Icons.speaker_rounded;
    }

    if (texto.contains('local') || texto.contains('salão')) {
      return Icons.location_on_rounded;
    }

    return Icons.storefront_rounded;
  }

  String formatarValor(dynamic valor) {
    final numero = double.tryParse(valor.toString()) ?? 0;

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget campoFormulario({
    required TextEditingController controller,
    required String titulo,
    required IconData icone,
    String? erro,
    TextInputType tipoTeclado = TextInputType.text,
    List<TextInputFormatter>? formatadores,
    int maxLinhas = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: tipoTeclado,
      inputFormatters: formatadores,
      maxLines: maxLinhas,
      style: const TextStyle(
        color: textoRoxo,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: titulo,
        hintStyle: TextStyle(
          color: textoRoxo.withValues(alpha: 0.65),
          fontSize: 15,
        ),
        prefixIcon: Icon(icone, color: roxoMedio, size: 23),
        errorText: erro,
        filled: true,
        fillColor: const Color(0xFFF5EAF8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9B9E4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD9B9E4), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: magenta, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget tituloSecao(String titulo, String subtitulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitulo,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget botaoAdicionar() {
    return SizedBox(
      width: double.infinity,
      height: 57,
      child: ElevatedButton.icon(
        onPressed: cadastrando ? null : adicionarFornecedor,
        icon: cadastrando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.add_circle_rounded,
                color: Colors.white,
                size: 25,
              ),
        label: Text(
          cadastrando ? 'Cadastrando...' : 'Adicionar Fornecedor',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: magenta,
          disabledBackgroundColor: magenta.withValues(alpha: 0.6),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  Widget cardFornecedor(dynamic fornecedor) {
    final nome = fornecedor['nome']?.toString() ?? 'Fornecedor';
    final categoria = fornecedor['categoria']?.toString() ?? 'Categoria';
    final telefone = fornecedor['telefone']?.toString() ?? '';
    final valor = fornecedor['valor'];

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 57,
            height: 57,
            decoration: BoxDecoration(
              color: const Color(0xFFF0DDF5),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(iconeCategoria(categoria), color: roxoMedio, size: 29),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textoRoxo,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  categoria,
                  style: const TextStyle(color: roxoMedio, fontSize: 13),
                ),
                if (telefone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        color: roxoMedio,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          telefone,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textoRoxo,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF0D5F6),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              formatarValor(valor),
              style: const TextStyle(
                color: roxoMedio,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget listaFornecedores() {
    if (carregando) {
      return const Padding(
        padding: EdgeInsets.all(35),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE879F9)),
        ),
      );
    }

    if (fornecedores.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 43,
              color: Colors.white.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nenhum fornecedor cadastrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Adicione os fornecedores que participarão do seu evento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: fornecedores.map((fornecedor) {
        return cardFornecedor(fornecedor);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoEscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD000C8), Color(0xFF8700A8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_rounded, size: 27),
            SizedBox(width: 10),
            Text(
              'Fornecedores',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool desktop = constraints.maxWidth >= 700;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  desktop
                      ? 'assets/images/fundo_fornecedores_desktop.png'
                      : 'assets/images/fundo_fornecedores.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF260033).withValues(alpha: 0.18),
                ),
              ),
              SafeArea(
                child: PageContainer(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Apresentação da tela
                        Row(
                          children: [
                            Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                color: magenta.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(19),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 35,
                              ),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seus Fornecedores',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Cadastre e organize os parceiros do seu evento.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Formulário
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBFF),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 17,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cadastrar fornecedor',
                                style: TextStyle(
                                  color: textoRoxo,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Preencha as informações do profissional ou empresa.',
                                style: TextStyle(
                                  color: textoRoxo.withValues(alpha: 0.65),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 20),

                              campoFormulario(
                                controller: nomeController,
                                titulo: 'Nome do fornecedor',
                                icone: Icons.person_outline_rounded,
                                erro: erroNome,
                              ),
                              const SizedBox(height: 13),

                              campoFormulario(
                                controller: categoriaController,
                                titulo: 'Categoria',
                                icone: Icons.grid_view_rounded,
                                erro: erroCategoria,
                              ),
                              const SizedBox(height: 13),

                              campoFormulario(
                                controller: telefoneController,
                                titulo: 'Telefone',
                                icone: Icons.phone_outlined,
                                erro: erroTelefone,
                                tipoTeclado: TextInputType.phone,
                                formatadores: [telefoneMask],
                              ),
                              const SizedBox(height: 13),

                              campoFormulario(
                                controller: emailController,
                                titulo: 'E-mail',
                                icone: Icons.mail_outline_rounded,
                                erro: erroEmail,
                                tipoTeclado: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 13),

                              campoFormulario(
                                controller: valorController,
                                titulo: 'Valor (R\$ 0,00)',
                                icone: Icons.payments_outlined,
                                erro: erroValor,
                                tipoTeclado: TextInputType.number,
                                formatadores: [valorFormatter],
                              ),
                              const SizedBox(height: 13),

                              campoFormulario(
                                controller: observacaoController,
                                titulo: 'Observação (opcional)',
                                icone: Icons.chat_bubble_outline_rounded,
                                maxLinhas: 2,
                              ),
                              const SizedBox(height: 20),

                              botaoAdicionar(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 27),

                        // Cabeçalho da listagem
                        Row(
                          children: [
                            Expanded(
                              child: tituloSecao(
                                'Fornecedores cadastrados',
                                'Parceiros vinculados ao seu evento',
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: magenta.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${fornecedores.length} ${fornecedores.length == 1 ? 'fornecedor' : 'fornecedores'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        listaFornecedores(),

                        const SizedBox(height: 20),

                        Center(
                          child: Icon(
                            Icons.handshake_outlined,
                            size: 55,
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                      ],
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
