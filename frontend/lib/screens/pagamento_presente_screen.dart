import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

enum MetodoPagamento { pix, cartao, boleto }

class PagamentoPresenteScreen extends StatefulWidget {
  final Map<String, dynamic> presente;
  final String mensagem;

  const PagamentoPresenteScreen({
    super.key,
    required this.presente,
    required this.mensagem,
  });

  @override
  State<PagamentoPresenteScreen> createState() =>
      _PagamentoPresenteScreenState();
}

class _PagamentoPresenteScreenState extends State<PagamentoPresenteScreen> {
  static const Color fundo = Color(0xFF210020);
  static const Color magenta = Color(0xFFE000B8);
  static const Color lilas = Color(0xFFDE74E9);

  final TextEditingController _emailController = TextEditingController();

  final NumberFormat _moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  MetodoPagamento _metodo = MetodoPagamento.pix;

  bool _carregando = false;
  String? _chaveTentativa;
  String? _metodoTentativa;
  String? _codigoPix;
  String? _imagemPix;
  String? _checkoutUrl;
  int? _pagamentoId;

  int get _presenteId =>
      int.tryParse(widget.presente['presente_id'].toString()) ?? 0;

  double get _valor =>
      double.tryParse(widget.presente['valor']?.toString() ?? '') ?? 0;

  String get _nome =>
      widget.presente['nome_presente']?.toString() ?? 'Presente';

  String get _valorFormatado => _moeda.format(_valor);

  @override
  void initState() {
    super.initState();
    _carregarEmail();
  }

  Future<void> _carregarEmail() async {
    try {
      final email = await ApiService.obterEmailConvidado();
      if (!mounted) return;
      _emailController.text = email ?? '';
    } catch (_) {
      // O convidado poderá informar o e-mail manualmente.
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _gerarUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes
        .map((valor) => valor.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  String get _codigoMetodo {
    switch (_metodo) {
      case MetodoPagamento.pix:
        return 'PIX';
      case MetodoPagamento.cartao:
        return 'CARTAO_CREDITO';
      case MetodoPagamento.boleto:
        return 'BOLETO';
    }
  }

  void _selecionarMetodo(MetodoPagamento metodo) {
    if (_carregando || metodo == _metodo) return;

    setState(() {
      _metodo = metodo;
      _codigoPix = null;
      _imagemPix = null;
      _checkoutUrl = null;
      _pagamentoId = null;
      _chaveTentativa = null;
      _metodoTentativa = null;
    });
  }

  void _mensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: const Color(0xFF50004F)),
    );
  }

  Future<void> _abrirCheckout(String link) async {
    final uri = Uri.tryParse(link);

    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        !(uri.host == 'mercadopago.com.br' ||
            uri.host.endsWith('.mercadopago.com.br') ||
            uri.host == 'mercadopago.com' ||
            uri.host.endsWith('.mercadopago.com'))) {
      throw Exception('O link de pagamento recebido é inválido.');
    }

    final abriu = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_self' : null,
    );

    if (!abriu) {
      throw Exception('Não foi possível abrir o Mercado Pago.');
    }
  }

  Future<void> _iniciarPagamento() async {
    if (_carregando) return;

    if (_presenteId <= 0 || _valor <= 0) {
      _mensagem('Os dados deste presente são inválidos.');
      return;
    }

    if (_metodo == MetodoPagamento.pix) {
      final email = _emailController.text.trim().toLowerCase();

      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) ||
          email.length > 254) {
        _mensagem('Informe um e-mail válido para gerar o Pix.');
        return;
      }
    }

    final metodo = _codigoMetodo;

    if (_chaveTentativa == null || _metodoTentativa != metodo) {
      _chaveTentativa = _gerarUuidV4();
      _metodoTentativa = metodo;
    }

    setState(() => _carregando = true);

    try {
      if (_metodo == MetodoPagamento.pix) {
        final resposta = await ApiService.criarPagamentoPixConvidado(
          presenteId: _presenteId,
          mensagem: widget.mensagem,
          emailPagador: _emailController.text.trim(),
          idempotencyKey: _chaveTentativa!,
        );

        final pix = resposta['pix'];

        if (pix is! Map || pix['qr_code'] == null) {
          throw Exception('O servidor não retornou o código Pix.');
        }

        if (!mounted) return;

        setState(() {
          _codigoPix = pix['qr_code'].toString();
          _imagemPix = pix['qr_code_base64']?.toString();
          _pagamentoId = int.tryParse(resposta['pagamento_id'].toString());
        });
      } else {
        final resposta = await ApiService.criarCheckoutPresenteConvidado(
          presenteId: _presenteId,
          mensagem: widget.mensagem,
          metodoPagamento: metodo,
          idempotencyKey: _chaveTentativa!,
        );

        final link = resposta['checkout_url']?.toString() ?? '';

        if (link.isEmpty) {
          throw Exception('O Mercado Pago não retornou o checkout.');
        }

        if (!mounted) return;

        setState(() {
          _checkoutUrl = link;
          _pagamentoId = int.tryParse(resposta['pagamento_id'].toString());
        });

        await _abrirCheckout(link);
      }
    } catch (erro) {
      _mensagem(erro.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Widget _opcao({
    required MetodoPagamento metodo,
    required IconData icone,
    required String titulo,
    required String descricao,
    String? etiqueta,
  }) {
    final selecionado = _metodo == metodo;

    return InkWell(
      onTap: _carregando ? null : () => _selecionarMetodo(metodo),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0xFF4B2050).withValues(alpha: 0.88)
              : const Color(0xFF291D30).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? lilas : Colors.white30,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selecionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selecionado ? lilas : Colors.white54,
              size: 27,
            ),
            const SizedBox(width: 16),
            Icon(icone, color: Colors.white, size: 36),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (etiqueta != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: metodo == MetodoPagamento.pix
                                ? const Color(0xFF116445)
                                : const Color(0xFF673082),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            etiqueta,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    descricao,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardPresente() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF39203F), Color(0xFF582350), Color(0xFF8B247B)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: lilas.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _nome.toLowerCase().contains('tv')
                  ? Icons.tv
                  : Icons.card_giftcard,
              color: Colors.white,
              size: 53,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Presente do evento',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  _valorFormatado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _painelPix() {
    if (_codigoPix == null) return const SizedBox.shrink();

    Uint8List? imagem;

    try {
      if (_imagemPix != null && _imagemPix!.isNotEmpty) {
        final conteudo = _imagemPix!.contains(',')
            ? _imagemPix!.split(',').last
            : _imagemPix!;
        imagem = base64Decode(conteudo);
      }
    } catch (_) {
      imagem = null;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_2, size: 35, color: Color(0xFF50004F)),
          const SizedBox(height: 10),
          const Text(
            'Pix gerado',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF210020),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escaneie o QR Code ou copie o código abaixo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF50004F),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (imagem != null) ...[
            const SizedBox(height: 15),
            Image.memory(
              imagem,
              width: 220,
              height: 220,
              errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 90),
            ),
          ],
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4F8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFE000B8).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Código Pix Copia e Cola',
                  style: TextStyle(
                    color: Color(0xFF50004F),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  _codigoPix!,
                  style: const TextStyle(
                    color: Color(0xFF210020),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _codigoPix!));
              _mensagem('Código Pix copiado!');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar código Pix'),
            style: ElevatedButton.styleFrom(
              backgroundColor: magenta,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pagamento nº ${_pagamentoId ?? "-"} • Aguardando confirmação',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
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
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: fundo),
              ),
              Container(color: fundo.withValues(alpha: 0.70)),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop ? 30 : 16,
                    vertical: 22,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.photo_camera_outlined,
                                color: Colors.white,
                                size: 36,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Momentz',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 48),
                            ],
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'Pagamento do Presente',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Escolha a forma de pagamento e '
                            'finalize seu presente com segurança.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _cardPresente(),
                          const SizedBox(height: 30),
                          const Text(
                            'Escolha a forma de pagamento',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _opcao(
                            metodo: MetodoPagamento.pix,
                            icone: Icons.qr_code_2,
                            titulo: 'Pix',
                            descricao:
                                'Gere o Pix e pague sem sair do MOMENTZ.',
                            etiqueta: 'Mais rápido',
                          ),
                          const SizedBox(height: 12),
                          _opcao(
                            metodo: MetodoPagamento.cartao,
                            icone: Icons.credit_card,
                            titulo: 'Cartão de crédito',
                            descricao:
                                'Continue no Mercado Pago. '
                                'Parcelamento conforme disponibilidade.',
                            etiqueta: 'Até 12x',
                          ),
                          const SizedBox(height: 12),
                          _opcao(
                            metodo: MetodoPagamento.boleto,
                            icone: Icons.receipt_long,
                            titulo: 'Boleto bancário',
                            descricao:
                                'Gere o boleto no Mercado Pago. '
                                'A confirmação depende da compensação.',
                          ),
                          if (_metodo == MetodoPagamento.pix &&
                              _codigoPix == null) ...[
                            const SizedBox(height: 22),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'E-mail do pagador',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF342039),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          if (_codigoPix == null)
                            SizedBox(
                              height: 60,
                              child: ElevatedButton.icon(
                                onPressed: _carregando
                                    ? null
                                    : _iniciarPagamento,
                                icon: _carregando
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.lock_outline),
                                label: Text(
                                  _carregando
                                      ? 'Preparando pagamento...'
                                      : _valorFormatado.isEmpty
                                      ? 'Pagar'
                                      : 'Pagar $_valorFormatado',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: magenta,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFF70305F,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          if (_codigoPix != null) _painelPix(),
                          if (_checkoutUrl != null && _codigoPix == null) ...[
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: _carregando
                                  ? null
                                  : () async {
                                      try {
                                        await _abrirCheckout(_checkoutUrl!);
                                      } catch (erro) {
                                        _mensagem(erro.toString());
                                      }
                                    },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text(
                                'Reabrir pagamento no Mercado Pago',
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Pagamento processado pelo Mercado Pago',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
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
