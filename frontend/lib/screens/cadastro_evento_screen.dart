import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class CadastroEventoScreen extends StatefulWidget {
  final int usuarioId;

  const CadastroEventoScreen({super.key, required this.usuarioId});

  @override
  State<CadastroEventoScreen> createState() => _CadastroEventoScreenState();
}

class _CadastroEventoScreenState extends State<CadastroEventoScreen> {
  static const Color roxoEscuro = Color(0xFF210020);
  static const Color roxo = Color(0xFF50004F);
  static const Color magenta = Color(0xFFE000B8);
  static const Color rosaClaro = Color(0xFFFCE4F8);

  final _formKey = GlobalKey<FormState>();

  final tipoController = TextEditingController();
  final convidadosController = TextEditingController();
  final descricaoController = TextEditingController();
  final dataController = TextEditingController();
  final localController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();

  String? tipoEventoSelecionado;
  String? estadoSelecionado;
  DateTime? dataSelecionada;
  bool cadastrando = false;

  final List<String> tiposEvento = [
    'Casamento',
    'Aniversário',
    'Formatura',
    'Chá de bebê',
    'Debutante',
    'Corporativo',
    'Outro',
  ];

  final List<String> estados = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];

  @override
  void dispose() {
    tipoController.dispose();
    convidadosController.dispose();
    descricaoController.dispose();
    dataController.dispose();
    localController.dispose();
    cidadeController.dispose();
    estadoController.dispose();
    super.dispose();
  }

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: roxo));
  }

  Future<void> selecionarData() async {
    final hoje = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? hoje,
      firstDate: DateTime(hoje.year, hoje.month, hoje.day),
      lastDate: DateTime(2100),
      helpText: 'Selecione a data do evento',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: magenta,
              onPrimary: Colors.white,
              onSurface: roxoEscuro,
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null && mounted) {
      setState(() {
        dataSelecionada = data;

        dataController.text =
            '${data.year}-'
            '${data.month.toString().padLeft(2, '0')}-'
            '${data.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> cadastrarEvento() async {
    if (cadastrando) return;

    if (!_formKey.currentState!.validate()) {
      mostrarMensagem('Preencha os campos obrigatórios.');
      return;
    }

    final quantidade = int.tryParse(convidadosController.text.trim());

    if (quantidade == null || quantidade <= 0) {
      mostrarMensagem('Informe uma quantidade válida de convidados.');
      return;
    }

    final tipo = tipoEventoSelecionado == 'Outro'
        ? tipoController.text.trim()
        : tipoEventoSelecionado!;

    setState(() => cadastrando = true);

    try {
      final resposta = await ApiService.cadastrarEvento(
        tipoEvento: tipo,
        quantidadeConvidados: quantidade,
        descricao: descricaoController.text.trim(),
        dataEvento: dataController.text,
        localEvento: localController.text.trim(),
        cidadeEvento: cidadeController.text.trim(),
        estadoEvento: estadoSelecionado!,
        usuarioId: widget.usuarioId,
      );

      if (!mounted) return;

      final mensagem =
          resposta['mensagem']?.toString() ?? 'Evento cadastrado com sucesso!';

      final codigo = resposta['codigo_evento']?.toString() ?? '-';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: magenta, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Evento criado!',
                    style: TextStyle(
                      color: roxoEscuro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mensagem,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: roxo, fontSize: 16),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Código do Evento',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: roxoEscuro,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  codigo,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: magenta,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Continuar',
                  style: TextStyle(color: magenta, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;

      mostrarMensagem('Não foi possível cadastrar o evento: $erro');
    } finally {
      if (mounted) {
        setState(() => cadastrando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roxoEscuro,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 800;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  desktop
                      ? 'assets/images/fundo_cadastro_evento_desktop.png'
                      : 'assets/images/fundo_cadastro_evento_mobile.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    _cabecalho(desktop),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 32 : 16,
                          vertical: desktop ? 35 : 22,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 950),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _tituloPagina(desktop),

                                  const SizedBox(height: 30),

                                  _formulario(),

                                  const SizedBox(height: 28),

                                  _botaoCadastrar(),

                                  const SizedBox(height: 35),
                                ],
                              ),
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
      height: desktop ? 90 : 75,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFED00C4), Color(0xFF800080), Color(0xFFED00C4)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          ),

          const Spacer(),

          Icon(
            Icons.photo_camera_outlined,
            color: Colors.white,
            size: desktop ? 48 : 36,
          ),

          const SizedBox(width: 12),

          Text(
            'MOMENTZ',
            style: TextStyle(
              color: Colors.white,
              fontSize: desktop ? 30 : 24,
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

  Widget _tituloPagina(bool desktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: desktop ? 110 : 72,
          height: desktop ? 110 : 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF00D4), Color(0xFF990099)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.calendar_month_outlined,
            color: Colors.white,
            size: desktop ? 60 : 42,
          ),
        ),

        const SizedBox(width: 16),

        Container(width: 4, height: desktop ? 95 : 65, color: magenta),

        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cadastrar Evento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: desktop ? 39 : 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Crie um novo evento no Momentz.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: desktop ? 19 : 14,
                ),
              ),
            ],
          ),
        ),

        if (desktop)
          const Icon(
            Icons.event_available,
            color: Color(0xFFFF79E9),
            size: 100,
          ),
      ],
    );
  }

  Widget _formulario() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _campo(
            icone: Icons.celebration_outlined,
            titulo: 'Tipo do Evento',
            dica: 'Selecione o tipo do evento',
            obrigatorio: true,
            child: DropdownButtonFormField<String>(
              initialValue: tipoEventoSelecionado,
              isExpanded: true,
              dropdownColor: Colors.white,
              iconEnabledColor: roxoEscuro,
              style: const TextStyle(
                color: roxoEscuro,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: _decoracaoInterna(
                'Selecione o tipo do evento',
              ).copyWith(hintText: null),
              hint: const Text(
                'Selecione o tipo do evento',
                style: TextStyle(color: Color(0xFF725672), fontSize: 15),
              ),
              items: tiposEvento.map((tipo) {
                return DropdownMenuItem(value: tipo, child: Text(tipo));
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  tipoEventoSelecionado = valor;
                });
              },
              validator: (valor) {
                if (valor == null) {
                  return 'Selecione o tipo do evento';
                }
                return null;
              },
            ),
          ),

          if (tipoEventoSelecionado == 'Outro') ...[
            const SizedBox(height: 12),
            _campo(
              icone: Icons.edit_outlined,
              titulo: 'Outro tipo de evento',
              dica: 'Informe o tipo do evento',
              obrigatorio: true,
              child: TextFormField(
                controller: tipoController,
                style: const TextStyle(color: roxoEscuro, fontSize: 16),

                decoration: _decoracaoInterna('Digite o tipo do evento'),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe o tipo do evento';
                  }
                  return null;
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          _campo(
            icone: Icons.groups_outlined,
            titulo: 'Quantidade de Convidados',
            dica: 'Informe a quantidade de convidados',
            obrigatorio: true,
            child: TextFormField(
              controller: convidadosController,
              style: const TextStyle(color: roxoEscuro, fontSize: 16),

              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decoracaoInterna('Ex.: 100'),
              validator: (valor) {
                final quantidade = int.tryParse(valor?.trim() ?? '');

                if (quantidade == null || quantidade <= 0) {
                  return 'Informe uma quantidade válida';
                }

                return null;
              },
            ),
          ),

          const SizedBox(height: 12),

          _campo(
            icone: Icons.description_outlined,
            titulo: 'Descrição',
            dica: 'Descreva os detalhes do seu evento',
            child: TextFormField(
              controller: descricaoController,
              style: const TextStyle(color: roxoEscuro, fontSize: 16),

              maxLines: 2,
              minLines: 1,
              decoration: _decoracaoInterna('Descrição do evento'),
            ),
          ),

          const SizedBox(height: 12),

          _campo(
            icone: Icons.calendar_today_outlined,
            titulo: 'Data do Evento',
            dica: 'Selecione a data do evento',
            obrigatorio: true,
            child: TextFormField(
              controller: dataController,
              style: const TextStyle(color: roxoEscuro, fontSize: 16),

              readOnly: true,
              onTap: selecionarData,
              decoration: _decoracaoInterna('Selecione a data').copyWith(
                suffixIcon: const Icon(Icons.calendar_month, color: roxo),
              ),
              validator: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'Selecione a data do evento';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 12),

          _campo(
            icone: Icons.location_on_outlined,
            titulo: 'Local do Evento',
            dica: 'Informe o local do evento',
            obrigatorio: true,
            child: TextFormField(
              controller: localController,
              style: const TextStyle(color: roxoEscuro, fontSize: 16),

              decoration: _decoracaoInterna('Nome do local'),
              validator: _validarObrigatorio,
            ),
          ),

          const SizedBox(height: 12),

          _campo(
            icone: Icons.location_city_outlined,
            titulo: 'Cidade',
            dica: 'Informe a cidade do evento',
            obrigatorio: true,
            child: TextFormField(
              controller: cidadeController,
              style: const TextStyle(color: roxoEscuro, fontSize: 16),
              decoration: _decoracaoInterna('Nome da cidade'),
              validator: _validarObrigatorio,
            ),
          ),

          const SizedBox(height: 12),

          _campo(
            icone: Icons.map_outlined,
            titulo: 'Estado',
            dica: 'Selecione o estado',
            obrigatorio: true,
            child: DropdownButtonFormField<String>(
              initialValue: estadoSelecionado,
              isExpanded: true,
              dropdownColor: Colors.white,
              iconEnabledColor: roxoEscuro,
              style: const TextStyle(
                color: roxoEscuro,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: _decoracaoInterna(
                'Selecione o estado',
              ).copyWith(hintText: null),
              hint: const Text(
                'Selecione o estado',
                style: TextStyle(color: Color(0xFF725672), fontSize: 15),
              ),
              items: estados.map((estado) {
                return DropdownMenuItem(value: estado, child: Text(estado));
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  estadoSelecionado = valor;
                  estadoController.text = valor ?? '';
                });
              },
              validator: (valor) {
                if (valor == null) {
                  return 'Selecione o estado';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _validarObrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este campo é obrigatório';
    }
    return null;
  }

  InputDecoration _decoracaoInterna(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF725672), fontSize: 15),
      labelStyle: const TextStyle(color: roxoEscuro),
      floatingLabelStyle: const TextStyle(color: roxoEscuro),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
    );
  }

  Widget _campo({
    required IconData icone,
    required String titulo,
    required String dica,
    required Widget child,
    bool obrigatorio = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: rosaClaro,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFFF1D5F0),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icone, color: roxo, size: 31),
          ),

          const SizedBox(width: 13),

          Container(
            width: 4,
            height: 65,
            decoration: BoxDecoration(
              color: magenta,
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: titulo),
                      if (obrigatorio)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                  style: const TextStyle(
                    color: roxoEscuro,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  dica,
                  style: const TextStyle(
                    color: Color(0xFF725672),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 5),

                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoCadastrar() {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: ElevatedButton.icon(
        onPressed: cadastrando ? null : cadastrarEvento,
        icon: cadastrando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add, size: 35),
        label: Text(
          cadastrando ? 'Cadastrando...' : 'Cadastrar Evento',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: magenta,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9A4A91),
          disabledForegroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
