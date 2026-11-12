import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://momentz-production.up.railway.app';

  static String? token;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _guestAccessKey = 'guest_access_token';
  static const String _guestRefreshKey = 'guest_refresh_token';
  static const String _guestIdKey = 'guest_id';
  static const String _guestEventIdKey = 'guest_event_id';
  static const String _guestEmailKey = 'guest_email';

  static MediaType? _tipoImagem(String nomeArquivo) {
    final extensao = nomeArquivo.split('.').last.toLowerCase();

    switch (extensao) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      case 'avif':
        return MediaType('image', 'avif');
      default:
        return null;
    }
  }

  static Future cadastrarFornecedor({
    required String nome,
    required String categoria,
    required String telefone,
    required String email,
    required double valor,
    required String observacao,
    required String statusFornecedor,
    required int eventoId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fornecedores'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        'categoria': categoria,
        'telefone': telefone,
        'email': email,
        'valor': valor,
        'observacao': observacao,
        'status_fornecedor': statusFornecedor,
        'evento_id': eventoId,
      }),
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return dados;
    }

    throw Exception(dados['erro'] ?? 'Erro ao cadastrar fornecedor.');
  }

  static Future cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String tipoUsuario,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        'tipo_usuario': tipoUsuario,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> cadastrarEvento({
    required String tipoEvento,
    required int quantidadeConvidados,
    required String descricao,
    required String dataEvento,
    required String localEvento,
    required String cidadeEvento,
    required String estadoEvento,
    required int usuarioId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/eventos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'tipo_evento': tipoEvento,
        'quantidade_convidados': quantidadeConvidados,
        'descricao': descricao,
        'data_evento': dataEvento,
        'local_evento': localEvento,
        'cidade_evento': cidadeEvento,
        'estado_evento': estadoEvento,
        'usuario_id': usuarioId,
      }),
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Map<String, dynamic>.from(dados);
    }

    throw Exception(dados['erro'] ?? 'Não foi possível cadastrar o evento.');
  }

  static Future login({required String email, required String senha}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode == 200) {
      token = dados['token'];
      return dados;
    }

    return {'erro': dados['erro'] ?? 'E-mail ou senha inválidos.'};
  }

  static Future cadastrarConvidado({
    required String nome,
    required String email,
    required int eventoId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/convidados'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'email': email, 'evento_id': eventoId}),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> buscarConvidados(int eventoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/convidados/evento/$eventoId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List<dynamic>> buscarEventoUsuario() async {
    final response = await http.get(
      Uri.parse('$baseUrl/eventos/meus-eventos'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body));
    }

    throw Exception(
      'Erro ao buscar eventos: ${response.statusCode} - ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> buscarEventoPorId(int eventoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/eventos/$eventoId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception(
      'Não foi possível buscar o evento: ${response.statusCode} - ${response.body}',
    );
  }

  static Future alterarStatusConvidado({
    required int convidadoId,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/convidados/$convidadoId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status_confirmacao': status}),
    );

    return jsonDecode(response.body);
  }

  static Future excluirConvidado(int convidadoId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/convidados/$convidadoId'),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> buscarFornecedores(int eventoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fornecedores/evento/$eventoId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<dynamic>.from(dados);
    }

    throw Exception(dados['erro'] ?? 'Erro ao buscar fornecedores.');
  }

  static Future<Map<String, dynamic>> verificarStatusMercadoPago() async {
    final response = await http.get(
      Uri.parse('$baseUrl/mercadopago/status'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(dados);
    }

    throw Exception(
      dados['erro'] ?? 'Não foi possível verificar o Mercado Pago.',
    );
  }

  static Future<Map<String, dynamic>> cadastrarPresente({
    required String nomePresente,
    required String descricao,
    required double? valor,
    required String linkLoja,
    required String statusProduto,
    required int eventoId,
    required String tipoPresente,
    required String icone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/presentes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome_presente': nomePresente,
        'descricao': descricao,
        'valor': valor,
        'link_loja': linkLoja,
        'status_produto': statusProduto,
        'evento_id': eventoId,
        'tipo_presente': tipoPresente,
        'icone': icone,
      }),
    );

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static Future<List<dynamic>> buscarPresentes(int eventoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/presentes/evento/$eventoId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body));
    }

    throw Exception(
      'Erro ao buscar presentes: ${response.statusCode} - ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> editarPresente({
    required int presenteId,
    required String nomePresente,
    required String descricao,
    required double? valor,
    required String linkLoja,
    required String statusProduto,
    required String tipoPresente,
    required String icone,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/presentes/$presenteId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome_presente': nomePresente,
        'descricao': descricao,
        'valor': valor,
        'link_loja': linkLoja,
        'status_produto': statusProduto,
        'tipo_presente': tipoPresente,
        'icone': icone,
      }),
    );

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static Future<Map<String, dynamic>> excluirPresente(int presenteId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/presentes/$presenteId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static Future<List<dynamic>> buscarFotosAdministrador(int eventoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fotos/admin/evento/$eventoId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<dynamic>.from(dados);
    }

    throw Exception(
      dados is Map
          ? dados['erro'] ?? 'Erro ao buscar fotos.'
          : 'Erro ao buscar fotos: ${response.statusCode}',
    );
  }

  static Future<List<dynamic>> buscarPresentesConvidado() async {
    String? accessToken = await obterTokenConvidado();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Sessão do convidado não encontrada.');
    }

    Future<http.Response> consultar(String token) {
      return http.get(
        Uri.parse('$baseUrl/presentes/convidado'),
        headers: {'Authorization': 'Bearer $token'},
      );
    }

    var response = await consultar(accessToken);

    if (response.statusCode == 401) {
      accessToken = await renovarSessaoConvidado();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Sua sessão expirou. Acesse o evento novamente.');
      }

      response = await consultar(accessToken);
    }

    dynamic dados;

    try {
      dados = jsonDecode(response.body);
    } catch (_) {
      throw Exception('O servidor retornou uma resposta inválida.');
    }

    if (response.statusCode == 200) {
      if (dados is List) {
        return List<dynamic>.from(dados);
      }

      throw Exception('Formato de resposta dos presentes inválido.');
    }

    final mensagem = dados is Map
        ? dados['erro'] ?? 'Não foi possível buscar os presentes.'
        : 'Erro ao buscar presentes: ${response.statusCode}';

    throw Exception(mensagem);
  }

  static Future<List<dynamic>> buscarMinhasFotosConvidado() async {
    String? accessToken = await obterTokenConvidado();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Sessão do convidado não encontrada.');
    }

    var response = await http.get(
      Uri.parse('$baseUrl/fotos/convidado/minhas'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 401) {
      accessToken = await renovarSessaoConvidado();

      if (accessToken == null) {
        throw Exception('Sua sessão expirou. Acesse o evento novamente.');
      }

      response = await http.get(
        Uri.parse('$baseUrl/fotos/convidado/minhas'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    }

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body));
    }

    throw Exception(
      'Erro ao buscar suas fotos: ${response.statusCode} - ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> uploadFotosConvidado({
    required List<Uint8List> arquivosBytes,
    required List<String> nomesArquivos,
  }) async {
    if (arquivosBytes.isEmpty || arquivosBytes.length != nomesArquivos.length) {
      throw Exception('Seleção de fotos inválida.');
    }

    if (arquivosBytes.length > 5) {
      throw Exception('Você pode enviar no máximo 5 fotos por vez.');
    }

    String? accessToken = await obterTokenConvidado();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Sessão do convidado não encontrada.');
    }

    Future<http.StreamedResponse> enviar(String token) async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/fotos/convidado/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      for (int i = 0; i < arquivosBytes.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'fotos',
            arquivosBytes[i],
            filename: nomesArquivos[i],
            contentType: _tipoImagem(nomesArquivos[i]),
          ),
        );
      }

      return request.send();
    }

    var response = await enviar(accessToken);

    if (response.statusCode == 401) {
      accessToken = await renovarSessaoConvidado();

      if (accessToken == null) {
        throw Exception('Sua sessão expirou. Acesse o evento novamente.');
      }

      response = await enviar(accessToken);
    }

    final resposta = await response.stream.bytesToString();

    dynamic dados;

    try {
      dados = jsonDecode(resposta);
    } catch (_) {
      throw Exception('O servidor retornou uma resposta inválida.');
    }

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(dados);
    }

    throw Exception(
      dados is Map
          ? dados['erro'] ?? 'Erro ao enviar fotos.'
          : 'Erro ao enviar fotos: ${response.statusCode}',
    );
  }

  static Future<Map<String, dynamic>> uploadFotosAdministrador({
    required List<Uint8List> arquivosBytes,
    required List<String> nomesArquivos,
    required int eventoId,
  }) async {
    if (arquivosBytes.isEmpty || arquivosBytes.length != nomesArquivos.length) {
      throw Exception('Seleção de fotos inválida.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/fotos/admin/$eventoId/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    for (int i = 0; i < arquivosBytes.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'fotos',
          arquivosBytes[i],
          filename: nomesArquivos[i],
          contentType: _tipoImagem(nomesArquivos[i]),
        ),
      );
    }

    final response = await request.send();
    final resposta = await response.stream.bytesToString();

    final dados = jsonDecode(resposta);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(dados);
    }

    throw Exception(
      dados is Map
          ? dados['erro'] ?? 'Erro ao enviar fotos.'
          : 'Erro ao enviar fotos: ${response.statusCode}',
    );
  }

  static Future<Map<String, dynamic>> uploadConvite({
    required Uint8List bytes,
    required String nomeArquivo,
    required int eventoId,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/eventos/$eventoId/convite'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'convite',
        bytes,
        filename: nomeArquivo,
        contentType: _tipoImagem(nomeArquivo),
      ),
    );

    final response = await request.send();
    final resposta = await response.stream.bytesToString();

    dynamic dados;

    try {
      dados = jsonDecode(resposta);
    } catch (_) {
      return {
        'erro': 'O servidor retornou uma resposta inválida.',
        'status': response.statusCode,
      };
    }

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(dados);
    }

    if (dados is Map<String, dynamic>) {
      return {
        'erro': dados['erro'] ?? 'Erro ao enviar o convite',
        'status': response.statusCode,
      };
    }

    return {'erro': 'Erro ao enviar o convite', 'status': response.statusCode};
  }

  static Future<Map<String, dynamic>> buscarOrcamento(int eventoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orcamento/$eventoId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(dados);
    }

    throw Exception(dados['erro'] ?? 'Erro ao buscar orçamento.');
  }

  static Future atualizarOrcamento({
    required int eventoId,
    required double orcamento,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orcamento/$eventoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'orcamento_total': orcamento}),
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return dados;
    }

    throw Exception(dados['erro'] ?? 'Erro ao atualizar orçamento.');
  }

  static Future<Map<String, dynamic>> enviarCodigoConvidado({
    required String codigoEvento,
    required String nome,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/convidados/enviar-codigo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'codigo_evento': codigoEvento,
        'nome': nome,
        'email': email,
      }),
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(dados['erro'] ?? 'Não foi possível enviar o código.');
    }

    return Map<String, dynamic>.from(dados);
  }

  // ============================================================
  // VALIDAR CÓDIGO DO CONVIDADO
  // ============================================================

  static Future<Map<String, dynamic>> validarCodigoConvidado({
    required String codigoEvento,
    required String email,
    required String codigo,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/convidados/validar-codigo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'codigo_evento': codigoEvento,
        'email': email,
        'codigo': codigo,
      }),
    );

    final dados = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(dados['erro'] ?? 'Código inválido ou expirado.');
    }

    final sessao = Map<String, dynamic>.from(dados['sessao']);

    await _storage.write(key: _guestAccessKey, value: sessao['access_token']);

    await _storage.write(key: _guestRefreshKey, value: sessao['refresh_token']);

    await _storage.write(
      key: _guestIdKey,
      value: dados['convidado_id'].toString(),
    );

    await _storage.write(
      key: _guestEventIdKey,
      value: dados['evento_id'].toString(),
    );

    await _storage.write(
      key: _guestEmailKey,
      value: email.trim().toLowerCase(),
    );

    return Map<String, dynamic>.from(dados);
  }

  static Future<String?> obterTokenConvidado() async {
    return await _storage.read(key: _guestAccessKey);
  }

  static Future<String?> renovarSessaoConvidado() async {
    final refreshToken = await _storage.read(key: _guestRefreshKey);

    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/convidados/renovar-sessao'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode != 200) {
      await limparSessaoConvidado();
      return null;
    }

    final dados = jsonDecode(response.body);
    final sessao = Map<String, dynamic>.from(dados['sessao']);

    await _storage.write(key: _guestAccessKey, value: sessao['access_token']);

    await _storage.write(key: _guestRefreshKey, value: sessao['refresh_token']);

    return sessao['access_token'];
  }

  // ============================================================
  // LOGOUT DO CONVIDADO
  // ============================================================

  static Future<void> logoutConvidado() async {
    final refreshToken = await _storage.read(key: _guestRefreshKey);

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await http.post(
          Uri.parse('$baseUrl/convidados/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      }
    } finally {
      await limparSessaoConvidado();
    }
  }

  static Future<void> limparSessaoConvidado() async {
    await _storage.delete(key: _guestAccessKey);
    await _storage.delete(key: _guestRefreshKey);
    await _storage.delete(key: _guestIdKey);
    await _storage.delete(key: _guestEventIdKey);
    await _storage.delete(key: _guestEmailKey);
  }
}
