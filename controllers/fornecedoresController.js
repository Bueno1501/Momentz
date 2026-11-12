const conexao = require("../config/db");

const verificarEventoAdministrador = (usuarioId, eventoId, callback) => {
  const sql = `
        SELECT evento_id
        FROM evento
        WHERE evento_id = ?
          AND usuario_id = ?
        LIMIT 1
    `;

  conexao.query(sql, [eventoId, usuarioId], (erro, resultados) => {
    if (erro) {
      return callback(erro);
    }

    callback(null, resultados.length > 0 ? resultados[0].evento_id : null);
  });
};

const cadastrarFornecedor = (req, res) => {
  if (req.usuario.tipo_usuario !== "Administrador") {
    return res.status(403).json({
      erro: "Acesso permitido somente ao administrador.",
    });
  }

  const {
    nome,
    categoria,
    telefone,
    email,
    valor,
    observacao,
    status_fornecedor,
    evento_id,
  } = req.body;

  if (!evento_id) {
    return res.status(400).json({
      erro: "O evento não foi informado.",
    });
  }

  verificarEventoAdministrador(
    req.usuario.usuario_id,
    evento_id,
    (erro, eventoValidado) => {
      if (erro) {
        console.error(erro);

        return res.status(500).json({
          erro: "Erro ao validar evento.",
        });
      }

      if (!eventoValidado) {
        return res.status(403).json({
          erro: "Evento não encontrado ou não pertence ao administrador.",
        });
      }

      const sql = `
                INSERT INTO fornecedor (
                    nome,
                    categoria,
                    telefone,
                    email,
                    valor,
                    observacao,
                    status_fornecedor,
                    evento_id
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            `;

      conexao.query(
        sql,
        [
          nome,
          categoria,
          telefone,
          email,
          valor,
          observacao,
          status_fornecedor,
          eventoValidado,
        ],
        (erro, resultado) => {
          if (erro) {
            console.error(erro);

            return res.status(500).json({
              erro: "Erro ao cadastrar fornecedor.",
            });
          }

          return res.status(201).json({
            mensagem: "Fornecedor cadastrado com sucesso!",
            fornecedor_id: resultado.insertId,
          });
        },
      );
    },
  );
};

const listarFornecedoresEvento = (req, res) => {
  if (req.usuario.tipo_usuario !== "Administrador") {
    return res.status(403).json({
      erro: "Acesso permitido somente ao administrador.",
    });
  }

  const { eventoId } = req.params;
  const usuarioId = req.usuario.usuario_id;

  verificarEventoAdministrador(usuarioId, eventoId, (erro, eventoValidado) => {
    if (erro) {
      console.error(erro);

      return res.status(500).json({
        erro: "Erro ao validar evento.",
      });
    }

    if (!eventoValidado) {
      return res.status(403).json({
        erro: "Evento não encontrado ou não pertence ao administrador.",
      });
    }

    const sql = `
                SELECT *
                FROM fornecedor
                WHERE evento_id = ?
                ORDER BY nome
            `;

    conexao.query(sql, [eventoValidado], (erro, resultado) => {
      if (erro) {
        console.error(erro);

        return res.status(500).json({
          erro: "Erro ao listar fornecedores.",
        });
      }

      return res.status(200).json(resultado);
    });
  });
};

module.exports = {
  cadastrarFornecedor,
  listarFornecedoresEvento,
};
