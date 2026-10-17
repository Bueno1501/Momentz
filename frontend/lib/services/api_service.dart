import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'https://momentz-production.up.railway.app';

  static String? token;

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

  static Future cadastrarEvento({
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

      headers: {'Content-type': 'application/json'},

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
    return jsonDecode(response.body);
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

  static Future login({required String email, required String senha}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/login'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({'email': email, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {'erro': 'email ou senha inválidos'};
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

  static Future<Map<String, dynamic>> buscarEventoUsuario(int usuarioId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/eventos/usuario/$usuarioId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {};
  }

  static Future<Map<String, dynamic>> buscarEventoPorId(int eventoId) async {
    final response = await http.get(Uri.parse('$baseUrl/eventos/$eventoId'));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Não foi possível buscar o evento');
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

      headers: {'Content-Type': 'application/json'},

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

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> buscarFornecedores(int eventoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fornecedores/evento/$eventoId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future cadastrarPresente({
    required String nomePresente,
    required String descricao,
    required double valor,
    required String linkLoja,
    required String statusProduto,
    required int eventoId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/presentes'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({
        'nome_presente': nomePresente,
        'descricao': descricao,
        'valor': valor,
        'link_loja': linkLoja,
        'status_produto': statusProduto,
        'evento_id': eventoId,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> buscarPresentes(int eventoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/presentes/evento/$eventoId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<List<dynamic>> buscarFotos(int eventoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fotos/evento/$eventoId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future uploadFoto({
    required Uint8List bytes,
    required String nomeArquivo,
    required int eventoId,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/fotos'));

    request.fields['evento_id'] = eventoId.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
        'foto',
        bytes,
        filename: nomeArquivo,
        contentType: _tipoImagem(nomeArquivo),
      ),
    );

    final response = await request.send();

    return response.statusCode == 201;
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
    final response = await http.get(Uri.parse('$baseUrl/orcamento/$eventoId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {};
  }

  static Future atualizarOrcamento({
    required int eventoId,
    required double orcamento,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orcamento/$eventoId'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({'orcamento_total': orcamento}),
    );

    return jsonDecode(response.body);
  }
}
