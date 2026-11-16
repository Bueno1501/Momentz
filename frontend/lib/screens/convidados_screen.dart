import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ConvidadosScreen extends StatefulWidget {
  final int eventoId;

  const ConvidadosScreen({super.key, required this.eventoId});

  @override
  State<ConvidadosScreen> createState() => _ConvidadosScreenState();
}

class _ConvidadosScreenState extends State<ConvidadosScreen> {
  static const Color roxoEscuro = Color(0xFF210020);
  static const Color roxo = Color(0xFF50004F);
  static const Color magenta = Color(0xFFE000B8);
  static const Color lilas = Color(0xFFF7E2F5);

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final buscaController = TextEditingController();

  List<dynamic> convidados = [];

  bool carregando = true;
  bool salvando = false;
  bool mostrarFormulario = false;
  bool enviandoConvite = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregarConvidados();
  }

  @override
  void didUpdateWidget(covariant ConvidadosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.eventoId != widget.eventoId) {
      carregarConvidados();
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    buscaController.dispose();
    super.dispose();
  }

  void aviso(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: roxo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String mensagemErro(Object erro) {
    return erro.toString().replaceFirst('Exception: ', '');
  }

  Future<void> carregarConvidados() async {
    if (!mounted) return;

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final resultado = await ApiService.buscarConvidados(widget.eventoId);

      if (!mounted) return;

      setState(() {
        convidados = resultado;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erro = mensagemErro(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> adicionarConvidado() async {
    if (salvando) return;

    final nome = nomeController.text.trim();
    final email = emailController.text.trim().toLowerCase();

    if (nome.isEmpty || email.isEmpty) {
      aviso('Preencha o nome e o e-mail.');
      return;
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      aviso('Informe um e-mail válido.');
      return;
    }

    setState(() => salvando = true);

    try {
      final resposta = await ApiService.cadastrarConvidado(
        nome: nome,
        email: email,
        eventoId: widget.eventoId,
      );

      if (!mounted) return;

      if (resposta['erro'] != null) {
        throw Exception(resposta['erro']);
      }

      nomeController.clear();
      emailController.clear();

      setState(() => mostrarFormulario = false);

      aviso('Convidado adicionado com sucesso!');

      await carregarConvidados();
    } catch (e) {
      aviso('Erro ao adicionar: ${mensagemErro(e)}');
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  Future<void> excluirConvidado(dynamic convidado) async {
    final id = int.tryParse('${convidado['convidado_id']}');

    if (id == null) {
      aviso('ID do convidado inválido.');
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Excluir convidado',
            style: TextStyle(color: roxoEscuro),
          ),
          content: Text(
            'Deseja realmente excluir ${convidado['nome']}? '
            'Essa ação não pode ser desfeita.',
            style: const TextStyle(color: roxo),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    try {
      final resposta = await ApiService.excluirConvidado(id);

      if (resposta['erro'] != null) {
        throw Exception(resposta['erro']);
      }

      if (!mounted) return;

      aviso('Convidado excluído com sucesso!');
      await carregarConvidados();
    } catch (e) {
      aviso('Erro ao excluir: ${mensagemErro(e)}');
    }
  }

  Future<void> editarStatus(dynamic convidado) async {
    final id = int.tryParse('${convidado['convidado_id']}');

    if (id == null) {
      aviso('ID do convidado inválido.');
      return;
    }

    String status = '${convidado['status_confirmacao'] ?? 'PENDENTE'}'
        .toUpperCase();

    if (!['PENDENTE', 'CONFIRMADO', 'RECUSADO'].contains(status)) {
      status = 'PENDENTE';
    }

    final novoStatus = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizar) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                'Editar ${convidado['nome'] ?? 'convidado'}',
                style: const TextStyle(
                  color: roxoEscuro,
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: RadioGroup<String>(
                groupValue: status,
                onChanged: (valor) {
                  if (valor != null) {
                    atualizar(() {
                      status = valor;
                    });
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final opcao in ['PENDENTE', 'CONFIRMADO', 'RECUSADO'])
                      RadioListTile<String>(
                        title: Text(
                          opcao == 'PENDENTE'
                              ? 'Pendente'
                              : opcao == 'CONFIRMADO'
                              ? 'Confirmado'
                              : 'Recusado',
                          style: const TextStyle(
                            color: roxoEscuro,
                            fontSize: 17,
                          ),
                        ),
                        activeColor: magenta,
                        value: opcao,
                      ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: magenta,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, status);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (novoStatus == null || !mounted) return;

    try {
      final resposta = await ApiService.alterarStatusConvidado(
        convidadoId: id,
        status: novoStatus,
      );

      if (resposta['erro'] != null) {
        throw Exception(resposta['erro']);
      }

      if (!mounted) return;

      aviso('Status atualizado com sucesso!');
      await carregarConvidados();
    } catch (e) {
      aviso('Erro ao atualizar: ${mensagemErro(e)}');
    }
  }

  Future<void> importarConvite() async {
    if (enviandoConvite) return;

    try {
      final resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
      );

      if (resultado.isEmpty) return;

      final arquivo = resultado.first;
      final Uint8List bytes = await arquivo.readAsBytes();

      if (!mounted) return;
      setState(() => enviandoConvite = true);

      final resposta = await ApiService.uploadConvite(
        bytes: bytes,
        nomeArquivo: arquivo.name,
        eventoId: widget.eventoId,
      );

      if (!mounted) return;

      if (resposta['erro'] != null) {
        throw Exception(resposta['erro']);
      }

      aviso('Convite enviado com sucesso!');
    } catch (e) {
      aviso('Erro ao importar convite: ${mensagemErro(e)}');
    } finally {
      if (mounted) {
        setState(() => enviandoConvite = false);
      }
    }
  }

  Future<void> gerarLinkEvento() async {
    try {
      final evento = await ApiService.buscarEventoPorId(widget.eventoId);

      final token = evento['token_convite']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception('Token do convite não encontrado.');
      }

      final link = Uri.base.resolve('/convite/$token').toString();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Link do evento',
              style: TextStyle(color: roxoEscuro),
            ),
            content: SelectableText(
              link,
              style: const TextStyle(color: roxo, fontSize: 16),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link));

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  aviso('Link copiado!');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar link'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      aviso('Erro ao gerar link: ${mensagemErro(e)}');
    }
  }

  int quantidade(dynamic convidado, String campo) {
    return int.tryParse('${convidado[campo] ?? 0}') ?? 0;
  }

  int totalPessoas(dynamic convidado) {
    return 1 +
        quantidade(convidado, 'criancas_0_3') +
        quantidade(convidado, 'criancas_4_7') +
        quantidade(convidado, 'acompanhantes_8_mais');
  }

  List<dynamic> get confirmados {
    return convidados.where((c) {
      return '${c['status_confirmacao']}'.toUpperCase() == 'CONFIRMADO';
    }).toList();
  }

  int get totalBebes => confirmados.fold<int>(
    0,
    (soma, c) => soma + quantidade(c, 'criancas_0_3'),
  );

  int get totalCriancas => confirmados.fold<int>(
    0,
    (soma, c) => soma + quantidade(c, 'criancas_4_7'),
  );

  int get totalAdultos => confirmados.fold<int>(
    0,
    (soma, c) => soma + 1 + quantidade(c, 'acompanhantes_8_mais'),
  );

  int get totalConfirmados => confirmados.length;

  int get totalPendentes => convidados.where((c) {
    return '${c['status_confirmacao']}'.toUpperCase() == 'PENDENTE';
  }).length;

  int get totalRecusados => convidados.where((c) {
    return '${c['status_confirmacao']}'.toUpperCase() == 'RECUSADO';
  }).length;

  void visualizarDetalhes(dynamic convidado) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            '${convidado['nome'] ?? 'Convidado'}',
            style: const TextStyle(
              color: roxoEscuro,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detalhe('E-mail', '${convidado['email'] ?? '-'}'),
                _detalhe(
                  'Status',
                  '${convidado['status_confirmacao'] ?? 'PENDENTE'}',
                ),
                _detalhe(
                  'Bebês (0 a 3 anos)',
                  '${quantidade(convidado, 'criancas_0_3')}',
                ),
                _detalhe(
                  'Crianças (4 a 7 anos)',
                  '${quantidade(convidado, 'criancas_4_7')}',
                ),
                _detalhe(
                  'Acompanhantes (8 anos ou mais)',
                  '${quantidade(convidado, 'acompanhantes_8_mais')}',
                ),
                _detalhe('Total de pessoas', '${totalPessoas(convidado)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: magenta,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                editarStatus(convidado);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar status'),
            ),
          ],
        );
      },
    );
  }

  Widget _detalhe(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: roxo,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 3),
          Text(valor, style: const TextStyle(color: roxoEscuro, fontSize: 17)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoEscuro,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 800;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                desktop
                    ? 'assets/images/momentz_fundo_desktop.png'
                    : 'assets/images/momentz_fundo_mobile.png',
                fit: BoxFit.cover,
              ),
              SafeArea(
                child: Column(
                  children: [
                    _cabecalho(desktop),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 32 : 14,
                          vertical: 24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _titulo(desktop),
                                const SizedBox(height: 25),
                                _estatisticas(desktop),
                                const SizedBox(height: 25),
                                _acoes(desktop),
                                if (mostrarFormulario) ...[
                                  const SizedBox(height: 20),
                                  _formulario(),
                                ],
                                const SizedBox(height: 25),
                                _listaConvidados(),
                                const SizedBox(height: 35),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cabecalho(bool desktop) {
    return Container(
      height: desktop ? 85 : 70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFED00C4), Color(0xFF800080), Color(0xFFED00C4)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          ),
          const Spacer(),
          Icon(
            Icons.photo_camera_outlined,
            color: Colors.white,
            size: desktop ? 43 : 32,
          ),
          const SizedBox(width: 10),
          Text(
            'MOMENTZ',
            style: TextStyle(
              color: Colors.white,
              fontSize: desktop ? 29 : 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _titulo(bool desktop) {
    return Row(
      children: [
        Container(
          width: desktop ? 85 : 65,
          height: desktop ? 85 : 65,
          decoration: BoxDecoration(
            color: magenta,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.groups,
            size: desktop ? 45 : 35,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Convidados',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: desktop ? 36 : 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Gerencie os convidados do seu evento',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: desktop ? 18 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _estatisticas(bool desktop) {
    final dados = [
      ('Confirmados', totalConfirmados, Icons.check_circle, Colors.green),
      ('Pendentes', totalPendentes, Icons.schedule, Colors.orange),
      ('Recusados', totalRecusados, Icons.cancel, Colors.red),
      ('Bebês', totalBebes, Icons.child_care, roxo),
      ('Crianças', totalCriancas, Icons.child_friendly, roxo),
      ('8 anos ou mais', totalAdultos, Icons.people, roxo),
    ];

    return Container(
      padding: EdgeInsets.all(desktop ? 22 : 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largura = constraints.maxWidth;
          final colunas = largura >= 720 ? 3 : 2;
          final espacamento = 12.0;
          final larguraCard = (largura - espacamento * (colunas - 1)) / colunas;

          return Wrap(
            spacing: espacamento,
            runSpacing: espacamento,
            children: dados.map((dado) {
              return SizedBox(
                width: larguraCard,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: lilas,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(dado.$3, color: dado.$4, size: desktop ? 32 : 27),
                      const SizedBox(height: 8),
                      Text(
                        '${dado.$2}',
                        style: TextStyle(
                          color: roxoEscuro,
                          fontSize: desktop ? 28 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dado.$1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: roxo,
                          fontSize: desktop ? 16 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _acoes(bool desktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;
        final colunas = largura >= 720 ? 3 : 1;
        final espacamento = 12.0;
        final larguraBotao = (largura - espacamento * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espacamento,
          runSpacing: espacamento,
          children: [
            SizedBox(
              width: larguraBotao,
              child: _botao('Adicionar convidado', Icons.person_add_alt_1, () {
                setState(() {
                  mostrarFormulario = !mostrarFormulario;
                });
              }),
            ),
            SizedBox(
              width: larguraBotao,
              child: _botao('Gerar link', Icons.link, gerarLinkEvento),
            ),
            SizedBox(
              width: larguraBotao,
              child: _botao(
                enviandoConvite ? 'Enviando convite...' : 'Importar convite',
                Icons.upload_file,
                enviandoConvite ? null : importarConvite,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _botao(String texto, IconData icone, VoidCallback? acao) {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: acao,
        icon: Icon(icone, size: 24),
        label: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: magenta,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracao(String titulo, IconData icone) {
    return InputDecoration(
      labelText: titulo,
      labelStyle: const TextStyle(color: roxo),
      prefixIcon: Icon(icone, color: roxo),
      filled: true,
      fillColor: lilas,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE3B4DF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: magenta, width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _formulario() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Adicionar convidado',
            style: TextStyle(
              color: roxoEscuro,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: nomeController,
            style: const TextStyle(color: roxoEscuro, fontSize: 17),
            decoration: _decoracao('Nome do convidado', Icons.person_outline),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: roxoEscuro, fontSize: 17),
            decoration: _decoracao('E-mail do convidado', Icons.email_outlined),
          ),
          const SizedBox(height: 18),
          _botao(
            salvando ? 'Adicionando...' : 'Confirmar cadastro',
            Icons.check,
            salvando ? null : adicionarConvidado,
          ),
        ],
      ),
    );
  }

  Widget _listaConvidados() {
    final termo = buscaController.text.trim().toLowerCase();

    final filtrados = convidados.where((convidado) {
      final nome = '${convidado['nome'] ?? ''}'.toLowerCase();
      final email = '${convidado['email'] ?? ''}'.toLowerCase();

      return nome.contains(termo) || email.contains(termo);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lista de convidados',
                  style: TextStyle(
                    color: roxoEscuro,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: carregarConvidados,
                icon: const Icon(Icons.refresh, color: magenta),
                tooltip: 'Atualizar lista',
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: buscaController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: roxoEscuro, fontSize: 17),
            decoration: _decoracao('Pesquisar convidado', Icons.search),
          ),
          const SizedBox(height: 20),
          if (carregando)
            const Padding(
              padding: EdgeInsets.all(35),
              child: Center(child: CircularProgressIndicator(color: magenta)),
            )
          else if (erro != null)
            Column(
              children: [
                Text(
                  erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                TextButton(
                  onPressed: carregarConvidados,
                  child: const Text('Tentar novamente'),
                ),
              ],
            )
          else if (filtrados.isEmpty)
            const Padding(
              padding: EdgeInsets.all(25),
              child: Text(
                'Nenhum convidado encontrado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: roxo, fontSize: 17),
              ),
            )
          else
            ...filtrados.map(_cartaoConvidado),
        ],
      ),
    );
  }

  Widget _cartaoConvidado(dynamic convidado) {
    final status = '${convidado['status_confirmacao'] ?? 'PENDENTE'}'
        .toUpperCase();

    final corStatus = status == 'CONFIRMADO'
        ? Colors.green
        : status == 'RECUSADO'
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lilas,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAC6E6)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 460;

          final informacoes = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${convidado['nome'] ?? 'Sem nome'}',
                style: const TextStyle(
                  color: roxoEscuro,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${convidado['email'] ?? 'Sem e-mail'}',
                softWrap: true,
                style: const TextStyle(color: roxo, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _etiqueta(status, corStatus),
                  _etiqueta('${totalPessoas(convidado)} pessoa(s)', roxo),
                ],
              ),
            ],
          );

          final acoes = Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'Visualizar detalhes',
                onPressed: () => visualizarDetalhes(convidado),
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: roxo,
                  size: 27,
                ),
              ),
              IconButton(
                tooltip: 'Editar status',
                onPressed: () => editarStatus(convidado),
                icon: const Icon(Icons.edit_outlined, color: magenta, size: 27),
              ),
              IconButton(
                tooltip: 'Excluir convidado',
                onPressed: () => excluirConvidado(convidado),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 27,
                ),
              ),
            ],
          );

          if (compacto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                informacoes,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: acoes),
              ],
            );
          }

          return Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: magenta,
                  size: 36,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(child: informacoes),
              const SizedBox(width: 12),
              acoes,
            ],
          );
        },
      ),
    );
  }

  Widget _etiqueta(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
