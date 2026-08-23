import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

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
      http.MultipartFile.fromBytes('foto', bytes, filename: nomeArquivo),
    );

    final response = await request.send();

    return response.statusCode == 201;
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
