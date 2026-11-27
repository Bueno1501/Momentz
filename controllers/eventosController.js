const conexao = require("../config/db");
const crypto = require("crypto");
const path = require("path");

const {
  enviarArquivo,
  gerarUrlTemporaria,
  excluirArquivos,
} = require("../services/r2Service");

const cadastrarEvento = (req, res) => {
  const {
    tipo_evento,
    quantidade_convidados,
    descricao,
    data_evento,
    local_evento,
    cidade_evento,
    estado_evento,
  } = req.body;

  // O ID vem do JWT, não do corpo da requisição.
  const usuarioId = req.usuario.usuario_id;

  const tokenConvite = crypto.randomBytes(32).toString("hex");

  const sql = `
        INSERT INTO evento (
            codigo_evento,
            tipo_evento,
            quantidade_convidados,
            descricao,
            data_evento,
            local_evento,
            cidade_evento,
            estado_evento,
            usuario_id,
            token_convite
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

  // Gera um código de até 10 caracteres.
  const codigoEvento = `EVE${crypto.randomBytes(4).toString("hex").slice(0, 7).toUpperCase()}`;

  conexao.query(
    sql,
    [
      codigoEvento,
      tipo_evento,
      quantidade_convidados,
      descricao,
      data_evento,
      local_evento,
      cidade_evento,
      estado_evento,
      usuarioId,
      tokenConvite,
    ],
    (erro, resultado) => {
      if (erro) {
        console.error("Erro ao cadastrar evento:", erro);

        if (erro.code === "ER_DUP_ENTRY") {
          return res.status(409).json({
            erro: "Não foi possível gerar um código único. Tente novamente.",
          });
        }

        return res.status(500).json({
          erro: "Erro ao cadastrar evento.",
        });
      }

      return res.status(201).json({
        mensagem: "Evento cadastrado com sucesso!",
        codigo_evento: codigoEvento,
        evento_id: resultado.insertId,
        token_convite: tokenConvite,
      });
    },
  );
};

// ============================================================
// BUSCAR TODOS OS EVENTOS DO ADMINISTRADOR
// ============================================================

const buscarEventoUsuario = (req, res) => {
  const usuarioId = req.usuario.usuario_id;

  const sql = `
        SELECT *
        FROM evento
        WHERE usuario_id = ?
        ORDER BY evento_id DESC
    `;

  conexao.query(sql, [usuarioId], (erro, resultado) => {
    if (erro) {
      console.error("Erro ao buscar eventos do administrador:", erro);

      return res.status(500).json({
        erro: "Erro ao buscar eventos.",
      });
    }

    // Retorna uma lista, mesmo quando não existem eventos.
    return res.status(200).json(resultado);
  });
};

// ============================================================
// ACESSAR EVENTO PELO CÓDIGO
// ============================================================

const acessarEvento = (req, res) => {
  const { codigo_evento } = req.body;

  if (!codigo_evento) {
    return res.status(400).json({
      erro: "Código do evento não informado.",
    });
  }

  const sql = `
        SELECT
            e.evento_id,
            e.codigo_evento,
            e.tipo_evento,
            e.quantidade_convidados,
            e.descricao,
            e.data_evento,
            e.local_evento,
            e.cidade_evento,
            e.estado_evento,
            u.nome AS nome_administrador
        FROM evento e
        INNER JOIN usuario u
            ON e.usuario_id = u.usuario_id
        WHERE e.codigo_evento = ?
    `;

  conexao.query(sql, [codigo_evento], (erro, resultado) => {
    if (erro) {
      console.error("Erro SQL ao buscar evento:", erro);

      return res.status(500).json({
        erro: "Erro ao buscar evento.",
      });
    }

    if (resultado.length === 0) {
      return res.status(404).json({
        erro: "Código do evento inválido.",
      });
    }

    return res.status(200).json({
      mensagem: "Evento encontrado.",
      evento: resultado[0],
    });
  });
};

const buscarEventoPorToken = (req, res) => {
  const { token } = req.params;

  if (!token) {
    return res.status(400).json({
      erro: "Token do convite não informado.",
    });
  }

  const sql = `
        SELECT
            evento_id,
            codigo_evento,
            tipo_evento,
            quantidade_convidados,
            descricao,
            data_evento,
            local_evento,
            cidade_evento,
            estado_evento,
            convite_url,
            fundo_convite_url
        FROM evento
        WHERE token_convite = ?
    `;

  conexao.query(sql, [token], async (erro, resultado) => {
    if (erro) {
      console.error("Erro ao buscar evento pelo convite:", erro);

      return res.status(500).json({
        erro: "Erro ao buscar evento pelo convite.",
      });
    }

    if (resultado.length === 0) {
      return res.status(404).json({
        erro: "Convite inválido ou evento não encontrado.",
      });
    }

    const evento = resultado[0];

    if (evento.convite_url) {
      try {
        if (evento.convite_url.startsWith("convites/")) {
          evento.convite_url = await gerarUrlTemporaria(evento.convite_url);
        } else if (!evento.convite_url.startsWith("http")) {
          evento.convite_url = null;
        }
      } catch (erroUrl) {
        console.error("Erro ao gerar URL do convite:", erroUrl);

        return res.status(502).json({
          erro: "Não foi possível carregar a imagem do convite.",
        });
      }
    }

    if (evento.fundo_convite_url) {
      try {
        if (
          evento.fundo_convite_url.startsWith(
            `fundos-convites/${evento.evento_id}/`,
          )
        ) {
          evento.fundo_convite_url = await gerarUrlTemporaria(
            evento.fundo_convite_url,
          );
        } else {
          evento.fundo_convite_url = null;
        }
      } catch (erroUrl) {
        console.error("Erro ao gerar URL do fundo do convite:", erroUrl);

        evento.fundo_convite_url = null;
      }
    }

    return res.status(200).json({
      mensagem: "Evento encontrado.",
      evento,
    });
  });
};

const importarConvite = async (req, res) => {
  const { eventoId } = req.params;
  const usuarioId = req.usuario.usuario_id;

  if (!req.file) {
    return res.status(400).json({
      erro: "Nenhum convite foi enviado.",
    });
  }

  const sqlVerificar = `
        SELECT evento_id
        FROM evento
        WHERE evento_id = ?
          AND usuario_id = ?
    `;

  conexao.query(
    sqlVerificar,
    [eventoId, usuarioId],
    async (erro, resultado) => {
      if (erro) {
        console.error("Erro ao verificar propriedade do evento:", erro);

        return res.status(500).json({
          erro: "Erro ao verificar evento.",
        });
      }

      if (resultado.length === 0) {
        return res.status(404).json({
          erro: "Evento não encontrado ou não pertence a este administrador.",
        });
      }

      const extensao = path.extname(req.file.originalname);
      const nomeArquivo = `${crypto.randomUUID()}${extensao}`;
      const chave = `convites/${eventoId}/${nomeArquivo}`;

      try {
        await enviarArquivo({
          chave,
          buffer: req.file.buffer,
          tipoConteudo: req.file.mimetype,
        });
      } catch (erroUpload) {
        console.error("Erro ao enviar convite para o R2:", erroUpload);

        return res.status(502).json({
          erro: "Não foi possível armazenar o convite.",
        });
      }

      const sqlAtualizar = `
                UPDATE evento
                SET convite_url = ?
                WHERE evento_id = ?
                  AND usuario_id = ?
            `;

      conexao.query(
        sqlAtualizar,
        [chave, eventoId, usuarioId],
        async (erroUpdate, resultadoUpdate) => {
          if (erroUpdate) {
            console.error("Erro ao salvar convite no banco:", erroUpdate);

            return res.status(500).json({
              erro: "Erro ao salvar convite.",
            });
          }

          if (resultadoUpdate.affectedRows === 0) {
            return res.status(404).json({
              erro: "Evento não encontrado.",
            });
          }

          try {
            const url = await gerarUrlTemporaria(chave);

            return res.status(200).json({
              mensagem: "Convite importado com sucesso!",
              convite_url: url,
            });
          } catch (erroUrl) {
            console.error("Erro ao gerar URL do convite:", erroUrl);

            return res.status(200).json({
              mensagem:
                "Convite armazenado, mas não foi possível gerar o link.",
              convite_url: null,
            });
          }
        },
      );
    },
  );
};

const importarFundoConvite = async (req, res) => {
  const eventoId = Number(req.params.eventoId);
  const usuarioId = req.usuario.usuario_id;

  if (!Number.isSafeInteger(eventoId) || eventoId <= 0) {
    return res.status(400).json({
      erro: "ID do evento inválido.",
    });
  }

  if (!req.file) {
    return res.status(400).json({
      erro: "Nenhuma imagem de fundo foi enviada.",
    });
  }

  const formatos = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
  };

  const extensao = formatos[req.file.mimetype];

  if (!extensao) {
    return res.status(400).json({
      erro: "Envie uma imagem JPG, PNG ou WEBP.",
    });
  }

  const buffer = req.file.buffer;

  const jpegValido =
    buffer.length >= 3 &&
    buffer[0] === 0xff &&
    buffer[1] === 0xd8 &&
    buffer[2] === 0xff;

  const pngValido =
    buffer.length >= 8 &&
    buffer
      .subarray(0, 8)
      .equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));

  const webpValido =
    buffer.length >= 12 &&
    buffer.toString("ascii", 0, 4) === "RIFF" &&
    buffer.toString("ascii", 8, 12) === "WEBP";

  const imagemValida =
    (extensao === ".jpg" && jpegValido) ||
    (extensao === ".png" && pngValido) ||
    (extensao === ".webp" && webpValido);

  if (!imagemValida) {
    return res.status(400).json({
      erro: "Arquivo de imagem inválido.",
    });
  }

  const consultarBanco = (sql, parametros) =>
    new Promise((resolve, reject) => {
      conexao.query(sql, parametros, (erro, resultado) => {
        if (erro) return reject(erro);
        resolve(resultado);
      });
    });

  let chaveNova = null;
  let uploadRealizado = false;
  let atualizacaoConfirmada = false;
  let atualizacaoIniciada = false;

  try {
    const eventos = await consultarBanco(
      `
                SELECT evento_id, fundo_convite_url
                FROM evento
                WHERE evento_id = ?
                  AND usuario_id = ?
            `,
      [eventoId, usuarioId],
    );

    if (eventos.length === 0) {
      return res.status(404).json({
        erro: "Evento não encontrado ou não pertence a este administrador.",
      });
    }

    const fundoAnterior = eventos[0].fundo_convite_url;

    const nomeArquivo = `${crypto.randomUUID()}${extensao}`;

    chaveNova = `fundos-convites/${eventoId}/${nomeArquivo}`;

    await enviarArquivo({
      chave: chaveNova,
      buffer: req.file.buffer,
      tipoConteudo: req.file.mimetype,
    });

    uploadRealizado = true;

    const urlTemporaria = await gerarUrlTemporaria(chaveNova);

    atualizacaoIniciada = true;

    const resultado = await consultarBanco(
      `
                UPDATE evento
                SET fundo_convite_url = ?
                WHERE evento_id = ?
                  AND usuario_id = ?
                  AND fundo_convite_url <=> ?
            `,
      [chaveNova, eventoId, usuarioId, fundoAnterior],
    );

    if (resultado.affectedRows === 0) {
      await excluirArquivos(chaveNova).catch((erro) => {
        console.error("Erro ao excluir novo fundo:", erro);
      });

      return res.status(409).json({
        erro: "O evento foi alterado. Tente novamente.",
      });
    }

    atualizacaoConfirmada = true;

    if (
      fundoAnterior &&
      fundoAnterior !== chaveNova &&
      fundoAnterior.startsWith(`fundos-convites/${eventoId}/`)
    ) {
      try {
        await excluirArquivos(fundoAnterior);
      } catch (erroExclusao) {
        console.error("Erro ao excluir fundo anterior:", erroExclusao);
      }
    }

    return res.status(200).json({
      mensagem: "Fundo do convite atualizado com sucesso!",
      fundo_convite_url: urlTemporaria,
    });
  } catch (erro) {
    console.error("Erro ao importar fundo do convite:", erro);

    // Remove o arquivo novo se a atualização
    // do banco ainda não tiver sido iniciada.
    if (
      uploadRealizado &&
      !atualizacaoConfirmada &&
      !atualizacaoIniciada &&
      chaveNova
    ) {
      try {
        await excluirArquivos(chaveNova);
      } catch (erroExclusao) {
        console.error("Erro ao remover arquivo não utilizado:", erroExclusao);
      }
    }

    return res.status(500).json({
      erro: "Não foi possível atualizar o fundo do convite.",
    });
  }
};

const buscarEventoPorId = (req, res) => {
  const { eventoId } = req.params;
  const usuarioId = req.usuario.usuario_id;

  const sql = `
        SELECT
            evento_id,
            tipo_evento,
            token_convite
        FROM evento
        WHERE evento_id = ?
          AND usuario_id = ?
    `;

  conexao.query(sql, [eventoId, usuarioId], (erro, resultado) => {
    if (erro) {
      console.error("Erro ao buscar evento:", erro);

      return res.status(500).json({
        erro: "Erro ao buscar evento.",
      });
    }

    if (resultado.length === 0) {
      return res.status(404).json({
        erro: "Evento não encontrado.",
      });
    }

    return res.status(200).json(resultado[0]);
  });
};

const gerarTokenGaleria = async (req, res) => {
    const eventoId = Number(req.params.eventoId);
    const usuarioId = req.usuario.usuario_id;

    if (!Number.isSafeInteger(eventoId) || eventoId <= 0) {
        return res.status(400).json({
            erro: 'ID do evento inválido.'
        });
    }

    const consultarBanco = (sql, parametros) =>
        new Promise((resolve, reject) => {
            conexao.query(sql, parametros, (erro, resultado) => {
                if (erro) return reject(erro);
                resolve(resultado);
            });
        });

    try {
        const novoToken = crypto.randomBytes(32).toString('hex');

        const sqlAtualizar = `
            UPDATE evento
            SET token_galeria = ?
            WHERE evento_id = ?
              AND usuario_id = ?
              AND token_galeria IS NULL
        `;

        await consultarBanco(sqlAtualizar, [
            novoToken,
            eventoId,
            usuarioId
        ]);

        const sqlBuscar = `
            SELECT evento_id, token_galeria
            FROM evento
            WHERE evento_id = ?
              AND usuario_id = ?
        `;

        const eventos = await consultarBanco(sqlBuscar, [
            eventoId,
            usuarioId
        ]);

        if (eventos.length === 0) {
            return res.status(404).json({
                erro: 'Evento não encontrado ou não pertence a este administrador.'
            });
        }

        return res.status(200).json({
            mensagem: 'Token da galeria obtido com sucesso!',
            evento_id: eventos[0].evento_id,
            token_galeria: eventos[0].token_galeria
        });

    } catch (erro) {
        console.error('Erro ao gerar token da galeria:', erro);

        return res.status(500).json({
            erro: 'Não foi possível gerar o token da galeria.'
        });
    }
};

module.exports = {
  cadastrarEvento,
  buscarEventoUsuario,
  acessarEvento,
  buscarEventoPorToken,
  importarConvite,
  importarFundoConvite,
  buscarEventoPorId,
  gerarTokenGaleria
};
