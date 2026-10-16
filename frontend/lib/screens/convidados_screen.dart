import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/page_container.dart';
import 'package:flutter/services.dart';

class ConvidadosScreen extends StatefulWidget {
  final int eventoId;

  const ConvidadosScreen({super.key, required this.eventoId});

  @override
  State<ConvidadosScreen> createState() => _ConvidadosScreenState();
}

class _ConvidadosScreenState extends State<ConvidadosScreen> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();

  List convidados = [];

  PlatformFile? conviteSelecionado;
  Uint8List? conviteBytes;

  Future atualizarStatus(int convidadoId, String status) async {
    await ApiService.alterarStatusConvidado(
      convidadoId: convidadoId,
      status: status,
    );

    await carregarConvidados();
  }

  Future carregarConvidados() async {
    final lista = await ApiService.buscarConvidados(widget.eventoId);

    setState(() {
      convidados = lista;
    });
  }

  Future<void> importarConvite() async {
    final arquivos = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (arquivos.isEmpty) {
      return;
    }

    final arquivo = arquivos.first;
    final bytes = await arquivo.readAsBytes();

    if (!mounted) return;

    setState(() {
      conviteSelecionado = arquivo;
      conviteBytes = bytes;
    });

    try {
      final resposta = await ApiService.uploadConvite(
        bytes: bytes,
        nomeArquivo: arquivo.name,
        eventoId: widget.eventoId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resposta.containsKey('convite_url')
                ? 'Convite salvo no evento com sucesso!'
                : resposta['erro'] ?? 'Erro ao salvar o convite',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar o convite ao servidor.'),
        ),
      );
    }
  }

  Future<void> gerarLinkEvento() async {
    try {
      final evento = await ApiService.buscarEventoPorId(widget.eventoId);

      debugPrint('Evento recebido pelo Flutter: $evento');
      debugPrint('ID do evento aberto: ${widget.eventoId}');

      final token = evento['token_convite'];

      debugPrint('Token recebido pelo Flutter: $token');

      if (token == null || token.toString().isEmpty) {
        throw Exception('Token do convite não encontrado');
      }

      final link = Uri.base.resolve('/convite/$token').toString();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Link do evento'),
          content: SelectableText(link),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));

                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(const SnackBar(content: Text('Link copiado!')));
              },
              child: const Text('Copiar link'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar link: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    carregarConvidados();
  }

  Future adicionarConvidado() async {
    if (nomeController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));

      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (!emailRegex.hasMatch(emailController.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um email válido.')));

      return;
    }

    final resposta = await ApiService.cadastrarConvidado(
      nome: nomeController.text,
      email: emailController.text,
      eventoId: widget.eventoId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resposta['mensagem'])));

    nomeController.clear();
    emailController.clear();

    await carregarConvidados();
  }

  Future removerConvidado(int convidadoId) async {
    await ApiService.excluirConvidado(convidadoId);

    await carregarConvidados();
  }

  void visualizarDetalhes(dynamic convidado) {
    String valor(String campo) {
      final dado = convidado[campo];
      if (dado == null || dado.toString().trim().isEmpty) {
        return 'Não informado';
      }
      return dado.toString();
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.person, color: Colors.deepPurple),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  valor('nome'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detalheConvidado(Icons.email, 'E-mail', valor('email')),
                _detalheConvidado(Icons.phone, 'Telefone', valor('telefone')),
                _detalheConvidado(
                  Icons.event_available,
                  'Confirmação',
                  valor('status_confirmacao'),
                ),
                const Divider(height: 28),
                const Text(
                  'Acompanhantes e crianças',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _detalheConvidado(
                  Icons.child_care,
                  'Crianças de 0 a 3 anos',
                  valor('criancas_0_3'),
                ),
                _detalheConvidado(
                  Icons.child_friendly,
                  'Crianças de 4 a 7 anos',
                  valor('criancas_4_7'),
                ),
                _detalheConvidado(
                  Icons.people,
                  'Acompanhantes de 8 anos ou mais',
                  valor('acompanhantes_8_mais'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Widget _detalheConvidado(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Colors.deepPurple, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 3),
                Text(valor, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int calcularTotalPessoas(dynamic convidado) {
    int quantidade(String campo) {
      return int.tryParse((convidado[campo] ?? 0).toString()) ?? 0;
    }

    return 1 +
        quantidade('criancas_0_3') +
        quantidade('criancas_4_7') +
        quantidade('acompanhantes_8_mais');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Convidados',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A176B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Importar convite',
            onPressed: importarConvite,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fundo_convidados.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF321044).withValues(alpha: 0.55),
            ),
          ),

          PageContainer(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (conviteSelecionado != null) ...[
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Convite do evento',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const SizedBox(height: 15),

                            if (['jpg', 'jpeg', 'png'].contains(
                              conviteSelecionado!.extension?.toLowerCase(),
                            ))
                              Image.memory(
                                conviteBytes!,
                                height: 300,
                                fit: BoxFit.contain,
                              )
                            else
                              Container(
                                height: 200,
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.picture_as_pdf, size: 70),
                                    SizedBox(height: 10),
                                    Text(
                                      'Arquivo PDF selecionado',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Convidado',
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email do Convidado',
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: adicionarConvidado,
                          child: const Text(
                            'Adicionar Convidado',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: gerarLinkEvento,
                          icon: const Icon(Icons.link),
                          label: const Text(
                            'Gerar link',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: convidados.length,

                    itemBuilder: (context, index) {
                      final convidado = convidados[index];

                      final totalPessoas = calcularTotalPessoas(convidado);

                      final status =
                          (convidado['status_confirmacao'] ?? 'PENDENTE')
                              .toString()
                              .toUpperCase();

                      final corStatus = status == 'CONFIRMADO'
                          ? Colors.green
                          : status == 'RECUSADO'
                          ? Colors.red
                          : Colors.orange;

                      return Card(
                        elevation: 5,
                        color: Colors.white,
                        shadowColor: Colors.black26,
                        margin: const EdgeInsets.symmetric(vertical: 7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => visualizarDetalhes(convidado),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE2F7),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF6A1B9A),
                                    size: 29,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        convidado['nome']?.toString() ??
                                            'Sem nome',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF30213B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        convidado['email']?.toString() ??
                                            'Sem e-mail',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                      Wrap(
                                        spacing: 7,
                                        runSpacing: 6,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEDE2F7),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$totalPessoas ${totalPessoas == 1 ? 'pessoa' : 'pessoas'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6A1B9A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: corStatus.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: corStatus,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Excluir convidado',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => removerConvidado(
                                    convidado['convidado_id'],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF6A1B9A),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
