class UsuarioModel{
  final String  nome;
  final String email;
  final String senha;
  final String tipoUsuario;

  UsuarioModel({
    required this.nome,
    required this.email,
    required this.senha,
    required this.tipoUsuario,
  });

  Map<String, dynamic> toJson(){
    return{
      'nome': nome,
      'email': email,
      'senha': senha,
      'tipo_usuario': tipoUsuario,
    };
  }

  factory UsuarioModel.fromJson(Map<String, dynamic > json) {
    return UsuarioModel(
      nome: json['nome'],
      email: json['email'],
      senha: json['senha']??'',
      tipoUsuario: json['tipo_usuario'],
    );
  }
}