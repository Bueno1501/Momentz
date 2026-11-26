import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;

class TelefoneBrasileiroFormatter extends TextInputFormatter {
  const TelefoneBrasileiroFormatter();

  String _formatar(String numeros) {
    if (numeros.isEmpty) return '';

    final buffer = StringBuffer();

    buffer.write('(');

    if (numeros.length <= 2) {
      buffer.write(numeros);
      return buffer.toString();
    }

    buffer.write(numeros.substring(0, 2));
    buffer.write(') ');

    final restante = numeros.substring(2);

    if (numeros.length == 11) {
      buffer.write(restante.substring(0, 1));
      buffer.write(' ');
      buffer.write(restante.substring(1, 5));
      buffer.write('-');
      buffer.write(restante.substring(5));
    } else if (numeros.length == 10) {
      buffer.write(restante.substring(0, 4));
      buffer.write('-');
      buffer.write(restante.substring(4));
    } else if (restante.length <= 4) {
      buffer.write(restante);
    } else if (restante.length <= 8) {
      buffer.write(restante.substring(0, 4));
      buffer.write('-');
      buffer.write(restante.substring(4));
    } else {
      buffer.write(restante.substring(0, 1));
      buffer.write(' ');
      buffer.write(restante.substring(1, 5));
      buffer.write('-');
      buffer.write(restante.substring(5));
    }

    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) {
      return newValue;
    }

    final numeros = newValue.text
        .replaceAll(RegExp(r'\D'), '')
        .substring(
          0,
          newValue.text.replaceAll(RegExp(r'\D'), '').length > 11
              ? 11
              : newValue.text.replaceAll(RegExp(r'\D'), '').length,
        );

    final textoFormatado = _formatar(numeros);

    // Mantém o cursor próximo à posição editada.
    final posicaoOriginal = newValue.selection.extentOffset;

    if (posicaoOriginal < 0) {
      return TextEditingValue(
        text: textoFormatado,
        selection: TextSelection.collapsed(offset: textoFormatado.length),
      );
    }

    final limite = posicaoOriginal.clamp(0, newValue.text.length);

    final digitosAntesCursor = newValue.text
        .substring(0, limite)
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, numeros.length);

    int novaPosicao = textoFormatado.length;

    if (digitosAntesCursor == 0) {
      novaPosicao = 0;
    } else {
      int encontrados = 0;

      for (int i = 0; i < textoFormatado.length; i++) {
        if (RegExp(r'\d').hasMatch(textoFormatado[i])) {
          encontrados++;

          if (encontrados == digitosAntesCursor) {
            novaPosicao = i + 1;
            break;
          }
        }
      }
    }

    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: novaPosicao),
    );
  }
}

class ConviteScreen extends StatefulWidget {
  final String token;
  final bool modoPrevia;
  final int? eventoId;

  const ConviteScreen({
    super.key,
    required this.token,
    this.modoPrevia = false,
    this.eventoId,
  });

  @override
  State<ConviteScreen> createState() => _ConviteScreenState();
}

class _ConviteScreenState extends State<ConviteScreen> {
  Map<String, dynamic>? convite;
  bool enviandoFundo = false;
  bool carregando = true;
  String? erro;

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final criancas03Controller = TextEditingController();
  final criancas47Controller = TextEditingController();
  final acompanhantes8Controller = TextEditingController();

  bool enviando = false;
  @override
  void initState() {
    super.initState();
    buscarEvento();
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    criancas03Controller.dispose();
    criancas47Controller.dispose();
    acompanhantes8Controller.dispose();

    super.dispose();
  }

  Future<void> alterarFundoConvite() async {
    final eventoId = widget.eventoId;

    if (!widget.modoPrevia ||
        eventoId == null ||
        enviandoFundo ||
        convite == null) {
      return;
    }

    setState(() => enviandoFundo = true);

    try {
      final resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (!mounted || resultado.isEmpty) return;

      final arquivo = resultado.first;

      final bytes = await arquivo.readAsBytes();

      if (!mounted) return;

      if (bytes.isEmpty) {
        throw Exception('A imagem selecionada está vazia.');
      }

      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception('A imagem deve possuir até 10 MB.');
      }

      final resposta = await ApiService.uploadFundoConvite(
        bytes: bytes,
        nomeArquivo: arquivo.name,
        eventoId: eventoId,
      );

      if (!mounted) return;

      final novaUrl = resposta['fundo_convite_url']?.toString();

      if (novaUrl == null || novaUrl.isEmpty) {
        throw Exception('Não foi possível carregar o novo fundo.');
      }

      setState(() {
        convite!['fundo_convite_url'] = novaUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fundo do convite atualizado com sucesso!'),
          backgroundColor: Color(0xFF50004F),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => enviandoFundo = false);
      }
    }
  }

  Future<void> buscarEvento() async {
    try {
      final resposta = await http.get(
        Uri.parse('${ApiService.baseUrl}/eventos/convite/${widget.token}'),
      );

      final dados = jsonDecode(resposta.body);

      if (!mounted) return;

      if (resposta.statusCode == 200) {
        setState(() {
          convite = Map<String, dynamic>.from(dados['evento']);
          carregando = false;
        });
      } else {
        setState(() {
          erro = dados['erro'] ?? 'Convite inválido';
          carregando = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        erro = 'Não foi possível acessar o convite.';
        carregando = false;
      });
    }
  }

  String valor(String campo, [String padrao = 'Não informado']) {
    final dado = convite?[campo];
    if (dado == null || dado.toString().trim().isEmpty) {
      return padrao;
    }
    return dado.toString();
  }

  String formatarData(dynamic data) {
    if (data == null) return 'Não informada';

    final texto = data.toString();
    final dataLocal = DateTime.tryParse(texto);

    if (dataLocal == null) return texto;

    return '${dataLocal.day.toString().padLeft(2, '0')}/'
        '${dataLocal.month.toString().padLeft(2, '0')}/'
        '${dataLocal.year}';
  }

  Future<void> _responderConvite(String status) async {
    if (widget.modoPrevia) return;

    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final telefone = telefoneController.text.replaceAll(RegExp(r'\D'), '');

    if (nome.isEmpty || email.isEmpty || telefone.isEmpty) {
      _mostrarAviso('Preencha nome, e-mail e telefone.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _mostrarAviso('Informe um e-mail válido.');
      return;
    }

    final textoCriancas03 = criancas03Controller.text.trim();
    final textoCriancas47 = criancas47Controller.text.trim();
    final textoAcompanhantes8 = acompanhantes8Controller.text.trim();

    final int? criancas03 = textoCriancas03.isEmpty
        ? 0
        : int.tryParse(textoCriancas03);

    final int? criancas47 = textoCriancas47.isEmpty
        ? 0
        : int.tryParse(textoCriancas47);

    final int? acompanhantes8 = textoAcompanhantes8.isEmpty
        ? 0
        : int.tryParse(textoAcompanhantes8);

    if (criancas03 == null ||
        criancas47 == null ||
        acompanhantes8 == null ||
        criancas03 < 0 ||
        criancas47 < 0 ||
        acompanhantes8 < 0) {
      _mostrarAviso('Informe quantidades inteiras iguais ou maiores que zero.');
      return;
    }

    setState(() => enviando = true);

    try {
      final resposta = await http.post(
        Uri.parse('${ApiService.baseUrl}/eventos/publico/${widget.token}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nome,
          'email': email,
          'telefone': telefone,
          'criancas_0_3': criancas03,
          'criancas_4_7': criancas47,
          'acompanhantes_8_mais': acompanhantes8,
          'status_confirmacao': status,
        }),
      );

      final dados = jsonDecode(resposta.body);

      if (!mounted) return;

      if (resposta.statusCode == 201) {
        _mostrarAviso(
          status == 'CONFIRMADO'
              ? 'Presença confirmada com sucesso!'
              : 'Recusa registrada com sucesso.',
        );
      } else {
        _mostrarAviso(
          dados['erro']?.toString() ?? 'Não foi possível registrar a resposta.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarAviso('Erro de conexão com o servidor.');
    } finally {
      if (mounted) {
        setState(() => enviando = false);
      }
    }
  }

  Widget fundoPadraoConvite() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF50004F), Color(0xFF210020), Color(0xFF120012)],
        ),
      ),
    );
  }

  Widget construirFundoConvite() {
    final fundoUrl = convite?['fundo_convite_url']?.toString() ?? '';

    final uri = Uri.tryParse(fundoUrl);

    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return fundoPadraoConvite();
    }

    return Image.network(
      fundoUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) {
        return fundoPadraoConvite();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (erro != null || convite == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Convite')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              erro ?? 'Não foi possível carregar o convite.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    final urlConvite = convite!['convite_url']?.toString();

    final urlCompleta = urlConvite == null || urlConvite.isEmpty
        ? null
        : (urlConvite.startsWith('http://') ||
              urlConvite.startsWith('https://'))
        ? urlConvite
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modoPrevia ? 'Prévia do convite' : 'Convite'),
        backgroundColor: const Color(0xFF2B1745),
        foregroundColor: Colors.white,

        actions: [
          if (widget.modoPrevia && widget.eventoId != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: enviandoFundo ? null : alterarFundoConvite,
                icon: enviandoFundo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.wallpaper_rounded, size: 20),
                label: Text(enviandoFundo ? 'Enviando...' : 'Alterar fundo'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFE000B8),
                  disabledForegroundColor: Colors.white70,
                  disabledBackgroundColor: const Color(0xFF50004F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: construirFundoConvite()),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF180824).withValues(alpha: 0.65),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    if (urlCompleta != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Convite do evento',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Image.network(
                                urlCompleta,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Não foi possível carregar a imagem do convite.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.mail_outline, size: 72),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 20),

                    Text(
                      'Você está convidado!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Venha participar do nosso ${valor('tipo_evento', 'evento')}!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),

                    const SizedBox(height: 24),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informações do evento',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _informacao(
                              Icons.celebration,
                              'Evento',
                              valor('tipo_evento'),
                            ),
                            _informacao(
                              Icons.calendar_month,
                              'Data',
                              formatarData(convite!['data_evento']),
                            ),
                            _informacao(
                              Icons.location_on,
                              'Local',
                              valor('local_evento'),
                            ),
                            _informacao(
                              Icons.location_city,
                              'Cidade',
                              '${valor('cidade_evento')} - '
                                  '${valor('estado_evento')}',
                            ),
                            if (valor('descricao', '').isNotEmpty)
                              _informacao(
                                Icons.message_outlined,
                                'Mensagem',
                                valor('descricao'),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Confirme sua presença',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Preencha seus dados para responder ao convite.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: nomeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: telefoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: const [TelefoneBrasileiroFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        hintText: '(43) 9 9999-9999',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: criancas03Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Crianças de 0 a 3 anos',
                        helperText:
                            'Quantidade de crianças nessa faixa etária.',
                        prefixIcon: Icon(Icons.child_care),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: criancas47Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Crianças de 4 a 7 anos',
                        helperText:
                            'Quantidade de crianças nessa faixa etária.',
                        prefixIcon: Icon(Icons.child_care),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: acompanhantes8Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Acompanhantes de 8 anos ou mais',
                        helperText:
                            'Inclua aqui os acompanhantes com 8 anos ou mais.',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: enviando || widget.modoPrevia
                                  ? null
                                  : () => _responderConvite('CONFIRMADO'),
                              child: enviando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Confirmar presença',
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: enviando || widget.modoPrevia
                                  ? null
                                  : () => _responderConvite('RECUSADO'),
                              child: enviando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Recusar convite',
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _informacao(IconData icone, String titulo, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$titulo: $texto',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAviso(String mensagem) {
    if (!mounted) return;

    final mensagemMinuscula = mensagem.toLowerCase();

    final sucesso = mensagemMinuscula.contains('sucesso');
    final recusado = mensagemMinuscula.contains('recusa registrada');

    final IconData icone;
    final Color cor;
    final String titulo;

    if (sucesso && !recusado) {
      icone = Icons.check_circle_rounded;
      cor = const Color(0xFF25A75A);
      titulo = 'Presença confirmada!';
    } else if (recusado) {
      icone = Icons.info_rounded;
      cor = const Color(0xFFE000B8);
      titulo = 'Convite recusado';
    } else {
      icone = Icons.warning_amber_rounded;
      cor = const Color(0xFFFF9800);
      titulo = 'Atenção!';
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              Icon(icone, color: cor, size: 65),
              const SizedBox(height: 14),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF300030),
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF574057), fontSize: 17),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 180,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE000B8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Entendi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
