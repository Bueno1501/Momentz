import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';

class PresentesScreen extends StatefulWidget {
  final int eventoId;

  const PresentesScreen({super.key, required this.eventoId});

  @override
  State<PresentesScreen> createState() => _PresentesScreenState();
}

class _PresentesScreenState extends State<PresentesScreen> {
  static const Color roxo = Color(0xFF26002F);
  static const Color roxoClaro = Color(0xFF4B075B);
  static const Color magenta = Color(0xFFE900C5);
  static const Color rosa = Color(0xFFFF42DA);
  static const Color branco = Color(0xFFFFF4FF);

  List<dynamic> presentes = [];

  int abaSelecionada = 0;
  bool carregando = true;
  bool erroCarregamento = false;

  static const Map<String, IconData> iconesPresentes = {
    'card_giftcard': Icons.card_giftcard,
    'cooking_pot': Icons.soup_kitchen,
    'blender': Icons.blender,
    'shopping_bag': Icons.shopping_bag,
    'restaurant': Icons.restaurant,
    'dinner_dining': Icons.dinner_dining,
    'coffee': Icons.coffee,
    'bed': Icons.bed,
    'chair': Icons.chair,
    'kitchen': Icons.kitchen,
    'local_laundry_service': Icons.local_laundry_service,
    'tv': Icons.tv,
    'smartphone': Icons.smartphone,
    'weekend': Icons.weekend,
    'light': Icons.light,
    'home': Icons.home,
    'favorite': Icons.favorite,
    'celebration': Icons.celebration,
  };

  @override
  void initState() {
    super.initState();
    carregarPresentes();
  }

  // ============================================================
  // CARREGAR PRESENTES
  // ============================================================

  Future<void> carregarPresentes() async {
    if (mounted) {
      setState(() {
        carregando = true;
        erroCarregamento = false;
      });
    }

    try {
      final lista = await ApiService.buscarPresentes(widget.eventoId);

      if (!mounted) return;

      setState(() {
        presentes = lista;
        carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        erroCarregamento = true;
      });

      mostrarMensagem('Não foi possível carregar os presentes.');
    }
  }

  // ============================================================
  // FILTROS
  // ============================================================

  List<dynamic> get presentesMomentz {
    return presentes.where((p) => p['tipo_presente'] == 'MOMENTZ').toList();
  }

  List<dynamic> get listasExternas {
    return presentes
        .where((p) => p['tipo_presente'] == 'LISTA_EXTERNA')
        .toList();
  }

  List<dynamic> get presentesExibidos {
    return abaSelecionada == 0 ? presentesMomentz : listasExternas;
  }

  // ============================================================
  // MENSAGENS
  // ============================================================

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: roxoClaro,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // FORMATAR VALOR
  // ============================================================

  String formatarValor(dynamic valor) {
    if (valor == null) return '';

    final numero = double.tryParse(valor.toString()) ?? 0;

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // MERCADO PAGO
  // ============================================================

  Future<bool> verificarMercadoPago() async {
    try {
      final resposta = await ApiService.verificarStatusMercadoPago();

      return resposta['conectado'] == true &&
          resposta['conta_validada'] == true;
    } catch (erro) {
      mostrarMensagem('Não foi possível verificar sua conta Mercado Pago.');
      return false;
    }
  }

  // ============================================================
  // CADASTRAR / EDITAR PRESENTE
  // ============================================================

  Future<bool> salvarPresente({
    required String nome,
    required String descricao,
    required String valor,
    required String link,
    required String tipo,
    required String icone,
    int? presenteId,
  }) async {
    final nomeLimpo = nome.trim();

    if (nomeLimpo.isEmpty) {
      mostrarMensagem('Informe o nome do presente.');
      return false;
    }

    double? valorNumerico;

    if (tipo == 'MOMENTZ') {
      final valorLimpo = valor
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');

      valorNumerico = double.tryParse(valorLimpo);

      if (valorNumerico == null || valorNumerico <= 0) {
        mostrarMensagem('Informe um valor válido.');
        return false;
      }

      final conectado = await verificarMercadoPago();

      if (!conectado) {
        mostrarMensagem(
          'Conecte e valide sua conta Mercado Pago para cadastrar presentes MOMENTZ.',
        );
        return false;
      }
    } else {
      if (link.trim().isEmpty) {
        mostrarMensagem('Informe o link da lista externa.');
        return false;
      }

      final uri = Uri.tryParse(link.trim());

      if (uri == null ||
          !['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty) {
        mostrarMensagem('Informe um link válido.');
        return false;
      }
    }

    try {
      final Map<String, dynamic> resposta;

      if (presenteId == null) {
        resposta = await ApiService.cadastrarPresente(
          nomePresente: nomeLimpo,
          descricao: descricao.trim(),
          valor: valorNumerico,
          linkLoja: link.trim(),
          statusProduto: 'DISPONIVEL',
          eventoId: widget.eventoId,
          tipoPresente: tipo,
          icone: icone,
        );
      } else {
        resposta = await ApiService.editarPresente(
          presenteId: presenteId,
          nomePresente: nomeLimpo,
          descricao: descricao.trim(),
          valor: valorNumerico,
          linkLoja: link.trim(),
          statusProduto: 'DISPONIVEL',
          tipoPresente: tipo,
          icone: icone,
        );
      }

      if (resposta.containsKey('erro')) {
        mostrarMensagem(resposta['erro'].toString());
        return false;
      }

      mostrarMensagem(resposta['mensagem'] ?? 'Presente salvo com sucesso.');

      await carregarPresentes();

      return true;
    } catch (erro) {
      debugPrint('Erro ao salvar presente: $erro');
      mostrarMensagem('Não foi possível salvar o presente.');
      return false;
    }
  }

  // ============================================================
  // ABRIR FORMULÁRIO
  // ============================================================

  Future<void> abrirFormulario({
    Map<String, dynamic>? presente,
    String? tipoInicial,
  }) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormularioPresenteDialog(
        presente: presente,
        tipoInicial: tipoInicial,
        onSalvar: salvarPresente,
      ),
    );
  }

  // ============================================================
  // EXCLUIR PRESENTE
  // ============================================================

  Future<void> excluirPresente(int presenteId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir presente'),
          content: const Text('Tem certeza que deseja excluir este presente?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final resposta = await ApiService.excluirPresente(presenteId);

      if (resposta.containsKey('erro')) {
        mostrarMensagem(resposta['erro'].toString());
        return;
      }

      mostrarMensagem(resposta['mensagem'] ?? 'Presente excluído.');

      await carregarPresentes();
    } catch (erro) {
      mostrarMensagem('Não foi possível excluir o presente.');
    }
  }

  // ============================================================
  // CARD DO PRESENTE
  // ============================================================

  Widget construirCard(Map<String, dynamic> presente) {
    final nome = presente['nome_presente']?.toString() ?? '';
    final valor = presente['valor'];

    final iconeNome = presente['icone']?.toString() ?? 'card_giftcard';

    final icone = iconesPresentes[iconeNome] ?? Icons.card_giftcard;

    final presenteId = int.tryParse(presente['presente_id'].toString());

    return Container(
      decoration: BoxDecoration(
        color: branco,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: rosa.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8D7F2), Color(0xFFE9B9E8)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(child: Icon(icone, size: 65, color: roxoClaro)),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 8, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: roxo,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    presente['tipo_presente'] == 'MOMENTZ'
                        ? formatarValor(valor)
                        : 'Lista externa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: roxo, fontSize: 14),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: presente['status_produto'] == 'DISPONIVEL'
                                ? const Color(0xFFD4F5C8)
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color:
                                    presente['status_produto'] == 'DISPONIVEL'
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  presente['status_produto'] == 'DISPONIVEL'
                                      ? 'Disponível'
                                      : presente['status_produto']
                                                ?.toString() ??
                                            'Indisponível',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: roxo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: roxo),
                        onSelected: (opcao) {
                          if (opcao == 'editar') {
                            abrirFormulario(
                              presente: Map<String, dynamic>.from(presente),
                            );
                          }

                          if (opcao == 'excluir' && presenteId != null) {
                            excluirPresente(presenteId);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'editar',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 19),
                                SizedBox(width: 9),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'excluir',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 19),
                                SizedBox(width: 9),
                                Text('Excluir'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÃO ADICIONAR
  // ============================================================

  Widget botaoAdicionar() {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton.icon(
        onPressed: () {
          abrirFormulario(
            tipoInicial: abaSelecionada == 0 ? 'MOMENTZ' : 'LISTA_EXTERNA',
          );
        },
        icon: const Icon(Icons.add, size: 30),
        label: const Text(
          'Adicionar presente',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: magenta,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: rosa,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BANNER
  // ============================================================

  Widget construirBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF390047), Color(0xFF750078), Color(0xFF31003B)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rosa.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [rosa, Color(0xFF9200A5)]),
              borderRadius: BorderRadius.all(Radius.circular(22)),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Presentes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Organize os presentes do seu evento.',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARDS DE MODALIDADE
  // ============================================================

  Widget construirAtalho({
    required String titulo,
    required String descricao,
    required IconData icone,
    required int aba,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          abaSelecionada = aba;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: branco,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [rosa, Color(0xFF9500A7)]),
                borderRadius: BorderRadius.all(Radius.circular(17)),
              ),
              child: Icon(icone, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: roxo,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    descricao,
                    style: const TextStyle(color: roxo, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ABAS
  // ============================================================

  Widget construirAbas() {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: magenta, width: 2),
        borderRadius: BorderRadius.circular(45),
        color: roxoClaro.withValues(alpha: 0.35),
      ),
      child: Row(
        children: [
          construirAba(
            titulo: 'Meus Presentes (${presentesMomentz.length})',
            icone: Icons.card_giftcard,
            indice: 0,
          ),
          construirAba(
            titulo: 'Listas Externas (${listasExternas.length})',
            icone: Icons.open_in_new,
            indice: 1,
          ),
        ],
      ),
    );
  }

  Widget construirAba({
    required String titulo,
    required IconData icone,
    required int indice,
  }) {
    final selecionada = abaSelecionada == indice;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            abaSelecionada = indice;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: selecionada
                ? const LinearGradient(colors: [rosa, Color(0xFFB900A7)])
                : null,
            color: selecionada ? null : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(38),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: Colors.white, size: 23),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.1,
                    fontWeight: selecionada ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GRADE RESPONSIVA
  // ============================================================

  Widget construirGrade() {
    if (presentesExibidos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 45),
        child: Column(
          children: [
            Icon(
              abaSelecionada == 0 ? Icons.card_giftcard : Icons.open_in_new,
              size: 55,
              color: rosa,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nenhum presente cadastrado ainda.',
              style: TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;

        final colunas = largura >= 1050
            ? 4
            : largura >= 650
            ? 3
            : largura >= 390
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: presentesExibidos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colunas,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: colunas == 1 ? 1.5 : 0.78,
          ),
          itemBuilder: (context, index) {
            return construirCard(
              Map<String, dynamic>.from(presentesExibidos[index]),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // TELA PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxo,
      appBar: AppBar(
        backgroundColor: magenta,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, color: Color(0xFFF0C8FF), size: 32),
            SizedBox(width: 10),
            Text(
              'MOMENTZ',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool mobile = constraints.maxWidth < 600;

          final String imagemFundo = mobile
              ? 'assets/images/fundo_presentes_mobile.png'
              : 'assets/images/fundo_presentes_desktop.png';

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagemFundo,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF27002F),
                          Color(0xFF43004E),
                          Color(0xFF200027),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Container(color: roxo.withValues(alpha: 0.30)),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1250),
                  child: RefreshIndicator(
                    color: magenta,
                    onRefresh: carregarPresentes,
                    child: ListView(
                      padding: EdgeInsets.all(mobile ? 13 : 20),
                      children: [
                        construirBanner(),
                        const SizedBox(height: 22),
                        construirAtalho(
                          titulo: 'Presentes pelo MOMENTZ',
                          descricao:
                              'Cadastre presentes com recebimento de pagamentos via Mercado Pago.',
                          icone: Icons.card_giftcard,
                          aba: 0,
                        ),
                        const SizedBox(height: 14),
                        construirAtalho(
                          titulo: 'Listas externas',
                          descricao:
                              'Adicione listas da Amazon, Magalu e outras lojas.',
                          icone: Icons.open_in_new,
                          aba: 1,
                        ),
                        const SizedBox(height: 25),
                        construirAbas(),
                        const SizedBox(height: 20),
                        if (carregando)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(color: rosa),
                            ),
                          )
                        else if (erroCarregamento)
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Não foi possível carregar os presentes.',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextButton(
                                  onPressed: carregarPresentes,
                                  child: const Text(
                                    'Tentar novamente',
                                    style: TextStyle(color: rosa),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          construirGrade(),
                        const SizedBox(height: 25),
                        botaoAdicionar(),
                        const SizedBox(height: 30),
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

// ============================================================
// FORMULÁRIO INDEPENDENTE
// ============================================================

class _FormularioPresenteDialog extends StatefulWidget {
  final Map<String, dynamic>? presente;
  final String? tipoInicial;

  final Future<bool> Function({
    required String nome,
    required String descricao,
    required String valor,
    required String link,
    required String tipo,
    required String icone,
    int? presenteId,
  })
  onSalvar;

  const _FormularioPresenteDialog({
    required this.onSalvar,
    this.presente,
    this.tipoInicial,
  });

  @override
  State<_FormularioPresenteDialog> createState() =>
      _FormularioPresenteDialogState();
}

class _FormularioPresenteDialogState extends State<_FormularioPresenteDialog> {
  static const Color roxo = Color(0xFF26002F);
  static const Color roxoClaro = Color(0xFF4B075B);
  static const Color magenta = Color(0xFFE900C5);
  static const Color rosa = Color(0xFFFF42DA);
  static const Color branco = Color(0xFFFFF4FF);

  late final TextEditingController nomeController;
  late final TextEditingController descricaoController;
  late final TextEditingController valorController;
  late final TextEditingController linkController;

  late String tipo;
  late String icone;

  bool salvando = false;

  static const Map<String, IconData> iconesPresentes =
      _PresentesScreenState.iconesPresentes;

  @override
  void initState() {
    super.initState();

    final presente = widget.presente;

    nomeController = TextEditingController(
      text: presente?['nome_presente']?.toString() ?? '',
    );

    descricaoController = TextEditingController(
      text: presente?['descricao']?.toString() ?? '',
    );

    valorController = TextEditingController(
      text: presente?['valor']?.toString().replaceAll('.', ',') ?? '',
    );

    linkController = TextEditingController(
      text: presente?['link_loja']?.toString() ?? '',
    );

    tipo = presente?['tipo_presente'] ?? widget.tipoInicial ?? 'MOMENTZ';

    icone = presente?['icone'] ?? 'card_giftcard';
  }

  // Os controllers são descartados somente quando o diálogo
  // realmente é removido da árvore de widgets.

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    valorController.dispose();
    linkController.dispose();
    super.dispose();
  }

  // ============================================================
  // SALVAR
  // ============================================================

  Future<void> salvar() async {
    if (salvando) return;

    setState(() {
      salvando = true;
    });

    final sucesso = await widget.onSalvar(
      nome: nomeController.text,
      descricao: descricaoController.text,
      valor: valorController.text,
      link: linkController.text,
      tipo: tipo,
      icone: icone,
      presenteId: widget.presente == null
          ? null
          : int.tryParse(widget.presente!['presente_id'].toString()),
    );

    if (!mounted) return;

    setState(() {
      salvando = false;
    });

    if (sucesso && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  // ============================================================
  // CAMPOS RESPONSIVOS
  // ============================================================

  Widget campo({
    required TextEditingController controller,
    required String label,
    required IconData iconeCampo,
    required bool mobile,
    TextInputType teclado = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      maxLines: maxLines,
      inputFormatters: formatters,
      style: TextStyle(color: roxo, fontSize: mobile ? 14 : 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(iconeCampo, color: magenta, size: mobile ? 20 : 24),
        labelStyle: TextStyle(color: roxoClaro, fontSize: mobile ? 13 : 15),
        isDense: mobile,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 13,
          vertical: mobile ? 12 : 17,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: roxo.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: magenta, width: 2),
        ),
      ),
    );
  }

  // ============================================================
  // CONSTRUIR FORMULÁRIO
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final presente = widget.presente;
    final espacamento = mobile ? 11.0 : 14.0;

    return Dialog(
      backgroundColor: branco,
      insetPadding: EdgeInsets.all(mobile ? 12 : 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mobile ? 17 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      presente == null
                          ? 'Adicionar presente'
                          : 'Editar presente',
                      style: TextStyle(
                        color: roxo,
                        fontSize: mobile ? 19 : 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: mobile
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    onPressed: salvando
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, color: roxo),
                  ),
                ],
              ),

              SizedBox(height: mobile ? 12 : 20),

              Text(
                'Tipo de presente',
                style: TextStyle(
                  color: roxo,
                  fontWeight: FontWeight.bold,
                  fontSize: mobile ? 13 : 15,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(
                      'MOMENTZ',
                      style: TextStyle(fontSize: mobile ? 12 : 14),
                    ),
                    selected: tipo == 'MOMENTZ',
                    selectedColor: rosa,
                    visualDensity: mobile
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    onSelected: presente != null || salvando
                        ? null
                        : (selecionado) {
                            if (selecionado) {
                              setState(() {
                                tipo = 'MOMENTZ';
                              });
                            }
                          },
                  ),
                  ChoiceChip(
                    label: Text(
                      'Lista externa',
                      style: TextStyle(fontSize: mobile ? 12 : 14),
                    ),
                    selected: tipo == 'LISTA_EXTERNA',
                    selectedColor: rosa,
                    visualDensity: mobile
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    onSelected: presente != null || salvando
                        ? null
                        : (selecionado) {
                            if (selecionado) {
                              setState(() {
                                tipo = 'LISTA_EXTERNA';
                              });
                            }
                          },
                  ),
                ],
              ),

              SizedBox(height: espacamento),

              campo(
                controller: nomeController,
                label: 'Nome do presente',
                iconeCampo: Icons.card_giftcard,
                mobile: mobile,
              ),

              SizedBox(height: espacamento),

              campo(
                controller: descricaoController,
                label: 'Descrição',
                iconeCampo: Icons.description,
                mobile: mobile,
                maxLines: 2,
              ),

              SizedBox(height: espacamento),

              if (tipo == 'MOMENTZ')
                campo(
                  controller: valorController,
                  label: 'Valor do presente',
                  iconeCampo: Icons.attach_money,
                  mobile: mobile,
                  teclado: const TextInputType.numberWithOptions(decimal: true),
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                ),

              if (tipo == 'LISTA_EXTERNA')
                campo(
                  controller: linkController,
                  label: 'Link da lista externa',
                  iconeCampo: Icons.link,
                  mobile: mobile,
                  teclado: TextInputType.url,
                ),

              SizedBox(height: mobile ? 15 : 20),

              Text(
                'Escolha um ícone',
                style: TextStyle(
                  color: roxo,
                  fontWeight: FontWeight.bold,
                  fontSize: mobile ? 14 : 16,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: mobile ? 8 : 10,
                runSpacing: mobile ? 8 : 10,
                children: iconesPresentes.entries.map((item) {
                  final selecionado = icone == item.key;
                  final tamanho = mobile ? 44.0 : 52.0;

                  return InkWell(
                    onTap: salvando
                        ? null
                        : () {
                            setState(() {
                              icone = item.key;
                            });
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: tamanho,
                      height: tamanho,
                      decoration: BoxDecoration(
                        color: selecionado
                            ? magenta
                            : roxo.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selecionado
                              ? magenta
                              : roxo.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Icon(
                        item.value,
                        color: selecionado ? Colors.white : roxo,
                        size: mobile ? 22 : 26,
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: mobile ? 20 : 28),

              SizedBox(
                width: double.infinity,
                height: mobile ? 46 : 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: magenta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: salvando ? null : salvar,
                  child: salvando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          presente == null
                              ? 'Cadastrar presente'
                              : 'Salvar alterações',
                          style: TextStyle(
                            fontSize: mobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
