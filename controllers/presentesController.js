const conexao = require("../config/db");

const { validarContaMercadoPago } = require("./mercadoPagoController");

const consultarBanco = (sql, parametros = []) => {
  return new Promise((resolve, reject) => {
    conexao.query(sql, parametros, (erro, resultados) => {
      if (erro) return reject(erro);
      resolve(resultados);
    });
  });
};

const verificarEventoAdministrador = async (eventoId, usuarioId) => {
  const sql = `
        SELECT evento_id
        FROM evento
        WHERE evento_id = ?
          AND usuario_id = ?
        LIMIT 1
    `;

  const resultado = await consultarBanco(sql, [eventoId, usuarioId]);

  return resultado.length > 0;
};

const cadastrarPresente = async (req, res) => {
  const {
    nome_presente,
    descricao,
    valor,
    link_loja,
    status_produto,
    evento_id,
    tipo_presente,
    icone,
  } = req.body;

  if (!req.usuario || req.usuario.tipo_usuario !== "Administrador") {
    return res.status(403).json({
      erro: "Apenas administradores podem cadastrar presentes.",
    });
  }

  if (!nome_presente || !evento_id || !tipo_presente) {
    return res.status(400).json({
      erro: "Nome, evento e tipo do presente são obrigatórios.",
    });
  }

  if (!["MOMENTZ", "LISTA_EXTERNA"].includes(tipo_presente)) {
    return res.status(400).json({
      erro: "Tipo de presente inválido.",
    });
  }

  if (
    tipo_presente === "MOMENTZ" &&
    (!Number.isFinite(Number(valor)) || Number(valor) <= 0)
  ) {
    return res.status(400).json({
      erro: "Informe um valor válido para o presente.",
    });
  }

  if (tipo_presente === "LISTA_EXTERNA" && !link_loja) {
    return res.status(400).json({
      erro: "Informe o link da lista externa.",
    });
  }

  try {
    const pertence = await verificarEventoAdministrador(
      evento_id,
      req.usuario.usuario_id,
    );

    if (!pertence) {
      return res.status(403).json({
        erro: "Você não tem permissão para gerenciar este evento.",
      });
    }

    if (tipo_presente === "MOMENTZ") {
      const validacao = await validarContaMercadoPago(req.usuario.usuario_id);

      if (!validacao.valida) {
        return res.status(403).json({
          erro: "Conecte e valide sua conta Mercado Pago antes de cadastrar presentes pelo MOMENTZ.",
          motivo: validacao.motivo,
        });
      }
    }

    const sql = `
            INSERT INTO presente (
                nome_presente,
                descricao,
                valor,
                link_loja,
                status_produto,
                evento_id,
                tipo_presente,
                icone
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;

    const resultado = await consultarBanco(sql, [
      nome_presente.trim(),
      descricao || null,
      tipo_presente === "MOMENTZ" ? Number(valor) : null,
      link_loja || null,
      status_produto || "DISPONIVEL",
      evento_id,
      tipo_presente,
      icone || "card_giftcard",
    ]);

    return res.status(201).json({
      mensagem: "Presente cadastrado com sucesso.",
      presente_id: resultado.insertId,
    });
  } catch (erro) {
    console.error("Erro ao cadastrar presente:", erro);

    return res.status(500).json({
      erro: "Erro ao cadastrar presente.",
    });
  }
};

// ============================================================
// LISTAR PRESENTES DO ADMINISTRADOR
// ============================================================

const listarPresentesEvento = async (req, res) => {
  const { eventoId } = req.params;

  if (!req.usuario || req.usuario.tipo_usuario !== "Administrador") {
    return res.status(403).json({
      erro: "Acesso permitido somente ao administrador.",
    });
  }

  try {
    const pertence = await verificarEventoAdministrador(
      eventoId,
      req.usuario.usuario_id,
    );

    if (!pertence) {
      return res.status(403).json({
        erro: "Você não tem acesso a este evento.",
      });
    }

    const sql = `
            SELECT *
            FROM presente
            WHERE evento_id = ?
            ORDER BY nome_presente
        `;

    const resultado = await consultarBanco(sql, [eventoId]);

    return res.status(200).json(resultado);
  } catch (erro) {
    console.error("Erro ao listar presentes:", erro);

    return res.status(500).json({
      erro: "Erro ao listar presentes.",
    });
  }
};

// ============================================================
// LISTAR PRESENTES DO CONVIDADO
// ============================================================

const listarPresentesConvidado = async (req, res) => {
  try {
    const sql = `
            SELECT
                presente_id,
                nome_presente,
                descricao,
                valor,
                link_loja,
                status_produto,
                tipo_presente,
                icone
            FROM presente
            WHERE evento_id = ?
              AND status_produto = 'DISPONIVEL'
            ORDER BY nome_presente
        `;

    const resultado = await consultarBanco(sql, [req.convidado.evento_id]);

    return res.status(200).json(resultado);
  } catch (erro) {
    console.error("Erro ao listar presentes do convidado:", erro);

    return res.status(500).json({
      erro: "Erro ao listar presentes.",
    });
  }
};

const editarPresente = async (req, res) => {
  const { presenteId } = req.params;

  const {
    nome_presente,
    descricao,
    valor,
    link_loja,
    status_produto,
    tipo_presente,
    icone,
  } = req.body;

  if (!req.usuario || req.usuario.tipo_usuario !== "Administrador") {
    return res.status(403).json({
      erro: "Acesso permitido somente ao administrador.",
    });
  }

  try {
    const sqlBusca = `
            SELECT p.evento_id
            FROM presente p
            INNER JOIN evento e ON e.evento_id = p.evento_id
            WHERE p.presente_id = ?
              AND e.usuario_id = ?
            LIMIT 1
        `;

    const encontrado = await consultarBanco(sqlBusca, [
      presenteId,
      req.usuario.usuario_id,
    ]);

    if (encontrado.length === 0) {
      return res.status(404).json({
        erro: "Presente não encontrado.",
      });
    }

    if (
      !nome_presente ||
      !["MOMENTZ", "LISTA_EXTERNA"].includes(tipo_presente)
    ) {
      return res.status(400).json({
        erro: "Dados inválidos para edição.",
      });
    }

    if (
      tipo_presente === "MOMENTZ" &&
      (!Number.isFinite(Number(valor)) || Number(valor) <= 0)
    ) {
      return res.status(400).json({
        erro: "Informe um valor válido.",
      });
    }

    if (tipo_presente === "LISTA_EXTERNA" && !link_loja) {
      return res.status(400).json({
        erro: "Informe o link da lista externa.",
      });
    }

    if (tipo_presente === "MOMENTZ") {
      const validacao = await validarContaMercadoPago(req.usuario.usuario_id);

      if (!validacao.valida) {
        return res.status(403).json({
          erro: "Conecte e valide sua conta Mercado Pago antes de utilizar presentes pelo MOMENTZ.",
          motivo: validacao.motivo,
        });
      }
    }

    const sql = `
            UPDATE presente
            SET
                nome_presente = ?,
                descricao = ?,
                valor = ?,
                link_loja = ?,
                status_produto = ?,
                tipo_presente = ?,
                icone = ?
            WHERE presente_id = ?
        `;

    await consultarBanco(sql, [
      nome_presente.trim(),
      descricao || null,
      tipo_presente === "MOMENTZ" ? Number(valor) : null,
      link_loja || null,
      status_produto || "DISPONIVEL",
      tipo_presente,
      icone || "card_giftcard",
      presenteId,
    ]);

    return res.status(200).json({
      mensagem: "Presente atualizado com sucesso.",
    });
  } catch (erro) {
    console.error("Erro ao editar presente:", erro);

    return res.status(500).json({
      erro: "Erro ao editar presente.",
    });
  }
};

// ============================================================
// EXCLUIR PRESENTE
// ============================================================

const excluirPresente = async (req, res) => {
  const { presenteId } = req.params;

  if (!req.usuario || req.usuario.tipo_usuario !== "Administrador") {
    return res.status(403).json({
      erro: "Acesso permitido somente ao administrador.",
    });
  }

  try {
    const sql = `
            DELETE p
            FROM presente p
            INNER JOIN evento e ON e.evento_id = p.evento_id
            WHERE p.presente_id = ?
              AND e.usuario_id = ?
        `;

    const resultado = await consultarBanco(sql, [
      presenteId,
      req.usuario.usuario_id,
    ]);

    if (resultado.affectedRows === 0) {
      return res.status(404).json({
        erro: "Presente não encontrado ou sem permissão.",
      });
    }

    return res.status(200).json({
      mensagem: "Presente excluído com sucesso.",
    });
  } catch (erro) {
    console.error("Erro ao excluir presente:", erro);

    return res.status(500).json({
      erro: "Erro ao excluir presente.",
    });
  }
};

module.exports = {
  cadastrarPresente,
  listarPresentesEvento,
  listarPresentesConvidado,
  editarPresente,
  excluirPresente,
};
