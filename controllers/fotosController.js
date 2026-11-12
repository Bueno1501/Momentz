const conexao = require("../config/db");
const crypto = require("crypto");

const { enviarArquivo, gerarUrlTemporaria } = require("../services/r2Service");

const path = require("path");

const buscarEventoAdministrador = (usuarioId, eventoId, callback) => {
  const sql = `
        SELECT evento_id
        FROM evento
        WHERE usuario_id = ?
            AND evento_id = ?
        LIMIT 1
    `;

  conexao.query(sql, [usuarioId, eventoId], (erro, resultados) => {
    if (erro) {
      return callback(erro);
    }

    if (resultados.length === 0) {
      return callback(null, null);
    }

    return callback(null, resultados[0].evento_id);
  });
};

const salvarFotos = async (arquivos, eventoId, convidadoId, res) => {
  const fotosSalvas = [];

  for (const arquivo of arquivos) {
    const extensoesPermitidas = {
      "image/jpeg": ".jpg",
      "image/png": ".png",
      "image/webp": ".webp",
      "image/gif": ".gif",
    };

    const extensao = extensoesPermitidas[arquivo.mimetype];

    if (!extensao) {
      return res.status(400).json({
        erro: "Formato de imagem não permitido.",
      });
    }

    const nomeArquivo = `${crypto.randomUUID()}${extensao}`;
    const chave = `fotos/${eventoId}/${nomeArquivo}`;

    try {
      await enviarArquivo({
        chave,
        buffer: arquivo.buffer,
        tipoConteudo: arquivo.mimetype,
      });

      const sql = `
                INSERT INTO foto (
                    url_foto,
                    nome_arquivo,
                    evento_id,
                    convidado_id
                )
                VALUES (?, ?, ?, ?)
            `;

      const resultado = await new Promise((resolve, reject) => {
        conexao.query(
          sql,
          [chave, nomeArquivo, eventoId, convidadoId],
          (erro, resultado) => {
            if (erro) {
              return reject(erro);
            }

            resolve(resultado);
          },
        );
      });

      let urlTemporaria = null;

      try {
        urlTemporaria = await gerarUrlTemporaria(chave);
      } catch (erroUrl) {
        console.error("Erro ao gerar URL temporária:", erroUrl);
      }

      fotosSalvas.push({
        foto_id: resultado.insertId,
        nome_arquivo: nomeArquivo,
        url_foto: urlTemporaria,
      });
    } catch (erro) {
      console.error("Erro ao salvar foto:", erro);

      return res.status(500).json({
        erro: "Ocorreu um erro durante o envio das fotos.",
        fotos_salvas: fotosSalvas,
        quantidade_salva: fotosSalvas.length,
      });
    }
  }

  return res.status(201).json({
    mensagem: "Fotos enviadas com sucesso!",
    quantidade: fotosSalvas.length,
    fotos: fotosSalvas,
  });
};

const uploadFotosConvidado = async (req, res) => {
  const arquivos = req.files;

  if (!arquivos || arquivos.length === 0) {
    return res.status(400).json({
      erro: "Selecione pelo menos uma foto.",
    });
  }

  if (arquivos.length > 5) {
    return res.status(400).json({
      erro: "Você pode enviar no máximo 5 fotos por vez.",
    });
  }

  const { evento_id, convidado_id } = req.convidado;

  return salvarFotos(arquivos, evento_id, convidado_id, res);
};

const uploadFotosAdministrador = (req, res) => {
  const arquivos = req.files;

  if (!arquivos || arquivos.length === 0) {
    return res.status(400).json({
      erro: "Selecione pelo menos uma foto.",
    });
  }

  if (req.usuario.tipo_usuario !== "Administrador") {
    return res.status(403).json({
      erro: "Acesso permitido somente ao administrador.",
    });
  }

  const usuarioId = req.usuario.usuario_id;
  const { eventoId } = req.params;

  buscarEventoAdministrador(
    usuarioId,
    eventoId,
    async (erro, eventoIdValidado) => {
      if (erro) {
        console.error("Erro ao validar evento:", erro);

        return res.status(500).json({
          erro: "Erro ao consultar evento.",
        });
      }

      if (!eventoIdValidado) {
        return res.status(403).json({
          erro: "Evento não encontrado ou não pertence ao administrador.",
        });
      }

      return salvarFotos(arquivos, eventoIdValidado, null, res);
    },
  );
};

const listarFotosConvidado = (req, res) => {
  const { evento_id, convidado_id } = req.convidado;

  const sql = `
        SELECT
            foto_id,
            nome_arquivo,
            url_foto,
            evento_id,
            convidado_id
        FROM foto
        WHERE evento_id = ?
          AND convidado_id = ?
        ORDER BY foto_id DESC
    `;

  conexao.query(sql, [evento_id, convidado_id], async (erro, resultados) => {
    if (erro) {
      console.error("Erro ao buscar fotos do convidado:", erro);

      return res.status(500).json({
        erro: "Erro ao buscar suas fotos.",
      });
    }

    try {
      const fotos = await Promise.all(
        resultados.map(async (foto) => ({
          ...foto,
          url_foto: await gerarUrlTemporaria(foto.url_foto),
        })),
      );

      return res.status(200).json(fotos);
    } catch (erroUrl) {
      console.error("Erro ao gerar URLs:", erroUrl);

      return res.status(500).json({
        erro: "Erro ao preparar visualização das fotos.",
      });
    }
  });
};

const listarFotosAdministrador = (req, res) => {
  if (req.usuario.tipo_usuario !== "Administrador") {
    return res.status(403).json({
      erro: "Acesso permitido somente ao administrador.",
    });
  }

  const usuarioId = req.usuario.usuario_id;
  const { eventoId } = req.params;

  buscarEventoAdministrador(usuarioId, eventoId, (erro, eventoIdValido) => {
    if (erro) {
      console.error("Erro ao consultar evento:", erro);

      return res.status(500).json({
        erro: "Erro ao consultar evento.",
      });
    }

    if (!eventoIdValido) {
      return res.status(403).json({
        erro: "Evento não encontrado ou não pertence ao administrador.",
      });
    }

    const sql = `
            SELECT
                f.foto_id,
                f.nome_arquivo,
                f.url_foto,
                f.evento_id,
                f.convidado_id,
                c.nome AS nome_convidado
            FROM foto f
            LEFT JOIN convidado c
                ON c.convidado_id = f.convidado_id
            WHERE f.evento_id = ?
            ORDER BY f.foto_id DESC
        `;

    conexao.query(sql, [eventoIdValido], async (erroFotos, resultados) => {
      if (erroFotos) {
        console.error("Erro ao listar fotos:", erroFotos);

        return res.status(500).json({
          erro: "Erro ao buscar fotos do evento.",
        });
      }

      try {
        const fotos = await Promise.all(
          resultados.map(async (foto) => ({
            ...foto,
            url_foto: await gerarUrlTemporaria(foto.url_foto),
          })),
        );

        return res.status(200).json(fotos);
      } catch (erroUrl) {
        console.error("Erro ao gerar URLs:", erroUrl);

        return res.status(500).json({
          erro: "Erro ao preparar visualização das fotos.",
        });
      }
    });
  });
};

module.exports = {
  uploadFotosConvidado,
  uploadFotosAdministrador,
  listarFotosConvidado,
  listarFotosAdministrador,
};
