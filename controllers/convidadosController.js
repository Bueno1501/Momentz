const conexao = require("../config/db");

const crypto = require("crypto");

const { enviarCodigoVerificacao } = require("../services/emailServices");

const cadastrarConvidado = (req, res) => {
  const { nome, email, telefone, evento_id } = req.body;
  const usuarioId = req.usuario.usuario_id;

  if (!nome || !email || !evento_id) {
    return res.status(400).json({
      erro: "Informe nome, e-mail e evento.",
    });
  }

  if (!Number.isInteger(Number(evento_id)) || Number(evento_id) <= 0) {
    return res.status(400).json({
      erro: "Evento inválido.",
    });
  }

  const tokenConvite = crypto.randomBytes(32).toString("hex");

  // O INSERT só acontece se o evento pertencer ao administrador.
  const sql = `
        INSERT INTO convidado (
            nome,
            email,
            telefone,
            evento_id,
            usuario_id,
            status_confirmacao,
            token_convite
        )
        SELECT ?, ?, ?, evento.evento_id, evento.usuario_id,
               'PENDENTE', ?
        FROM evento
        WHERE evento.evento_id = ?
          AND evento.usuario_id = ?
    `;

  conexao.query(
    sql,
    [
      nome.trim(),
      email.trim().toLowerCase(),
      telefone || null,
      tokenConvite,
      evento_id,
      usuarioId,
    ],
    (erro, resultado) => {
      if (erro) {
        console.error(erro);

        return res.status(500).json({
          erro: "Erro ao cadastrar convidado.",
        });
      }

      if (resultado.affectedRows === 0) {
        return res.status(404).json({
          erro: "Evento não encontrado ou não pertence a este administrador.",
        });
      }

      return res.status(201).json({
        mensagem: "Convidado cadastrado com sucesso.",
        convidado_id: resultado.insertId,
      });
    },
  );
};

const buscarConvitePorToken = (req, res) => {
  const { token } = req.params;

  const sql = `
        SELECT
            convidado.convidado_id,
            convidado.nome,
            convidado.email,
            convidado.telefone,
            convidado.status_confirmacao,
            evento.evento_id,
            evento.codigo_evento,
            evento.tipo_evento,
            evento.data_evento,
            evento.local_evento,
            evento.cidade_evento,
            evento.estado_evento,
            evento.descricao
        FROM convidado INNER JOIN evento ON convidado.evento_id = evento.evento_id
        WHERE convidado.token_convite = ?
    `;

  conexao.query(sql, [token], (erro, resultado) => {
    if (erro) {
      console.log(erro);

      return res.status(500).json({
        erro: "Erro ao buscar convite",
      });
    }

    if (resultado.length === 0) {
      return res.status(404).json({
        erro: "Convite não encontrado ou inválido",
      });
    }

    return res.status(200).json({
      mensagem: "Convite encontrado",
      convite: resultado[0],
    });
  });
};

const listarConvidadosPorEvento = (req, res) => {
  const { eventoId } = req.params;
  const usuarioId = req.usuario.usuario_id;

  const sql = `
        SELECT convidado.*
        FROM convidado
        INNER JOIN evento
            ON convidado.evento_id = evento.evento_id
        WHERE evento.evento_id = ?
          AND evento.usuario_id = ?
        ORDER BY convidado.nome
    `;

  conexao.query(sql, [eventoId, usuarioId], (erro, resultado) => {
    if (erro) {
      console.error(erro);

      return res.status(500).json({
        erro: "Erro ao buscar convidados.",
      });
    }

    return res.status(200).json(resultado);
  });
};

const alterarStatusConvidados = (req, res) => {
  const { convidadoId } = req.params;
  const { status_confirmacao } = req.body;
  const usuarioId = req.usuario.usuario_id;

  const statusValidos = ["CONFIRMADO", "PENDENTE", "RECUSADO"];

  if (!statusValidos.includes(status_confirmacao)) {
    return res.status(400).json({
      erro: "Status de confirmação inválido.",
    });
  }

  const sql = `
        UPDATE convidado
        INNER JOIN evento
            ON convidado.evento_id = evento.evento_id
        SET convidado.status_confirmacao = ?
        WHERE convidado.convidado_id = ?
          AND evento.usuario_id = ?
    `;

  conexao.query(
    sql,
    [status_confirmacao, convidadoId, usuarioId],
    (erro, resultado) => {
      if (erro) {
        console.error(erro);

        return res.status(500).json({
          erro: "Erro ao atualizar status.",
        });
      }

      if (resultado.affectedRows === 0) {
        return conexao.query(
          `SELECT convidado.convidado_id
                     FROM convidado
                     INNER JOIN evento
                        ON convidado.evento_id = evento.evento_id
                     WHERE convidado.convidado_id = ?
                       AND evento.usuario_id = ?`,
          [convidadoId, usuarioId],
          (erroBusca, convidados) => {
            if (erroBusca) {
              console.error(erroBusca);

              return res.status(500).json({
                erro: "Erro ao verificar convidado.",
              });
            }

            if (convidados.length === 0) {
              return res.status(404).json({
                erro: "Convidado não encontrado ou não pertence aos seus eventos.",
              });
            }

            return res.status(200).json({
              mensagem: "O convidado já estava com esse status.",
            });
          },
        );
      }

      return res.status(200).json({
        mensagem: "Status atualizado com sucesso.",
      });
    },
  );
};

const excluirConvidado = (req, res) => {
  const { convidadoId } = req.params;
  const usuarioId = req.usuario.usuario_id;

  const sql = `
        DELETE convidado
        FROM convidado
        INNER JOIN evento
            ON convidado.evento_id = evento.evento_id
        WHERE convidado.convidado_id = ?
          AND evento.usuario_id = ?
    `;

  conexao.query(sql, [convidadoId, usuarioId], (erro, resultado) => {
    if (erro) {
      console.error(erro);

      return res.status(500).json({
        erro: "Erro ao excluir convidado.",
      });
    }

    if (resultado.affectedRows === 0) {
      return res.status(404).json({
        erro: "Convidado não encontrado ou não pertence aos seus eventos.",
      });
    }

    return res.status(200).json({
      mensagem: "Convidado excluído com sucesso.",
    });
  });
};

const responderConvite = (req, res) => {
  const { token } = req.params;
  const { status_confirmacao } = req.body;

  if (!status_confirmacao) {
    return res.status(400).json({
      erro: "Status de confirmação não informado",
    });
  }

  if (
    status_confirmacao !== "CONFIRMADO" &&
    status_confirmacao !== "RECUSADO"
  ) {
    return res.status(400).json({
      erro: "Status inválido",
    });
  }

  const sql = `

        UPDATE convidado
        SET status_confirmacao = ?
        WHERE token_convite = ?
    `;

  conexao.query(sql, [status_confirmacao, token], (erro, resultado) => {
    if (erro) {
      console.log(erro);

      return res.status(500).json({
        erro: "Erro ao atualizar confirmação",
      });
    }

    if (resultado.affectedRows === 0) {
      return res.status(404).json({
        erro: "Convite não encontrado",
      });
    }

    return res.status(200).json({
      mensagem: "Resposta do convite registrada",
      status_confirmacao: status_confirmacao,
    });
  });
};

const cadastrarConvidadoPublico = (req, res) => {
  const { token } = req.params;

  const {
    nome,
    email,
    telefone,
    criancas_0_3 = 0,
    criancas_4_7 = 0,
    acompanhantes_8_mais = 0,
    status_confirmacao,
  } = req.body;

  if (!nome || !email || !telefone) {
    return res.status(400).json({
      erro: "Informe nome, email e telefone.",
    });
  }

  if (!["CONFIRMADO", "RECUSADO"].includes(status_confirmacao)) {
    return res.status(400).json({
      erro: "Resposta do convite inválida.",
    });
  }

  const faixas = [criancas_0_3, criancas_4_7, acompanhantes_8_mais];

  const quantidadeValidas = faixas.every(
    (quantidade) =>
      Number.isInteger(Number(quantidade)) && Number(quantidade) >= 0,
  );

  if (!quantidadeValidas) {
    return res.status(400).json({
      erro: "As quantidades devem ser númerps inteiros não negativos.",
    });
  }

  const totalAcompanhantes = faixas.reduce(
    (total, quantidade) => total + Number(quantidade),
    0,
  );

  const sqlEvento = `
        SELECT evento_id, usuario_id
        FROM evento
        WHERE token_convite = ?
    `;

  conexao.query(sqlEvento, [token], (erro, eventos) => {
    if (erro) {
      console.log(erro);
      return res.status(500).json({
        erro: "Erro ao localizar o evento.",
      });
    }

    if (eventos.length === 0) {
      return res.status(404).json({
        erro: "Convite inválido ou evento não encontrado.",
      });
    }

    const evento = eventos[0];

    const sqlConvidado = `
            INSERT INTO convidado (
                nome,
                email,
                telefone,
                evento_id,
                usuario_id,
                status_confirmacao,
                quantidade_acompanhantes,
                criancas_0_3,
                criancas_4_7,
                acompanhantes_8_mais
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

    conexao.query(
      sqlConvidado,
      [
        nome.trim(),
        email.trim(),
        telefone.trim(),
        evento.evento_id,
        evento.usuario_id,
        status_confirmacao,
        totalAcompanhantes,
        Number(criancas_0_3),
        Number(criancas_4_7),
        Number(acompanhantes_8_mais),
      ],
      (erroInsert, resultado) => {
        if (erroInsert) {
          console.log(erroInsert);
          return res.status(500).json({
            erro: "Erro ao registrar sua resposta.",
          });
        }

        return res.status(201).json({
          mensagem: "Resposta registrada com sucesso!",
          convidado_id: resultado.insertId,
          status_confirmacao,
          quantidade_acompanhantes: totalAcompanhantes,
        });
      },
    );
  });
};

const enviarCodigoConvidado = (req, res) => {
  const { codigo_evento, nome, email } = req.body;

  if (!codigo_evento || !nome || !email) {
    return res.status(400).json({
      erro: "Informe o código do evento, nome e email.",
    });
  }

  const nomeLimpo = nome.trim();
  const emailLimpo = email.trim().toLowerCase();
  const codigoEvento = codigo_evento.trim().toUpperCase();

  if (nomeLimpo.length < 2 || nomeLimpo.length > 80) {
    return res.status(400).json({
      erro: "informe um nome válido.",
    });
  }

  if (
    emailLimpo.length > 100 ||
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailLimpo)
  ) {
    return res.status(400).json({
      erro: "Informe um e-mail válido.",
    });
  }

  if (!process.env.EMAIL_CODE_SECRET) {
    console.error("EMAIL_CODE_SECRET não configurado.");

    return res.status(500).json({
      erro: "Serviço de verificação indisponível.",
    });
  }

  const sqlEvento = `
        SELECT
        evento_id,
        data_evento,
        CASE
            WHEN data_evento IS NULL THEN 1
            WHEN DATE(
                CONVERT_TZ(UTC_TIMESTAMP(), '+00:00', '-03:00')
            ) > DATE_ADD(data_evento, INTERVAL 10 DAY)
            THEN 1
            ELSE 0
        END AS evento_encerrado
    FROM evento
    WHERE codigo_evento = ?

    `;

  conexao.query(sqlEvento, [codigoEvento], (erro, eventos) => {
    if (erro) {
      console.error("Erro ao localizar evento:", erro);

      return res.status(500).json({
        erro: "Erro ao localizar evento.",
      });
    }

    if (eventos.length === 0) {
      return res.status(400).json({
        erro: "Código do evento inválido.",
      });
    }

    const eventoId = eventos[0].evento_id;

    if (eventos[0].evento_encerrado === 1) {
      return res.status(403).json({
        erro: "O prazo de acesso a este evento foi encerrado.",
      });
    }

    const sqlVerificacao = `
            SELECT criado_em, bloqueado_ate
            FROM convidado_verificacao WHERE
            evento_id = ? AND email = ?
        `;

    conexao.query(
      sqlVerificacao,
      [eventoId, emailLimpo],
      async (erroConsulta, verificacoes) => {
        if (erroConsulta) {
          console.error(erroConsulta);

          return res.status(500).json({
            erro: "Erro ao verificar solicitação.",
          });
        }

        if (verificacoes.length > 0) {
          const verificacao = verificacoes[0];

          if (
            verificacao.bloqueado_ate &&
            new Date(verificacao.bloqueado_ate) > new Date()
          ) {
            return res.status(429).json({
              erro: "Aguarde antes de solicitar outro código.",
            });
          }

          const ultimaSolicitacao = new Date(verificacao.criado_em);

          const segundosDecorridos =
            (Date.now() - ultimaSolicitacao.getTime()) / 1000;

          if (segundosDecorridos < 60) {
            return res.status(429).json({
              erro: "Aguarde 60 segundos antes de solicitar outro código.",
            });
          }
        }

        const codigo = crypto.randomInt(100000, 1000000).toString();

        const codigoHash = crypto
          .createHmac("sha256", process.env.EMAIL_CODE_SECRET)
          .update(`${eventoId}:${emailLimpo}:${codigo}`)
          .digest("hex");

        const sqlSalvar = `
                    INSERT INTO convidado_verificacao (
                        evento_id,
                        nome,
                        email,
                        codigo_hash,
                        tentativas,
                        expira_em,
                        bloqueado_ate,
                        usado_em
                    )
                    VALUES (
                        ?, ?, ?, ?, 0,
                        DATE_ADD(NOW(), INTERVAL 5 MINUTE),
                        NULL,
                        NULL
                    )
                    ON DUPLICATE KEY UPDATE
                        nome = VALUES(nome),
                        codigo_hash = VALUES(codigo_hash),
                        tentativas = 0,
                        expira_em = DATE_ADD(NOW(), INTERVAL 5 MINUTE),
                        bloqueado_ate = NULL,
                        usado_em = NULL,
                        criado_em = CURRENT_TIMESTAMP
                `;

        conexao.query(
          sqlSalvar,
          [eventoId, nomeLimpo, emailLimpo, codigoHash],
          async (erroSalvar) => {
            if (erroSalvar) {
              console.error(erroSalvar);

              return res.status(500).json({
                erro: "Erro ao gerar código de confirmação.",
              });
            }

            try {
              await enviarCodigoVerificacao(emailLimpo, codigo);

              return res.status(200).json({
                mensagem: "Código de confirmação enviado.",
                validade_minutos: 5,
              });
            } catch (erroEmail) {
              console.error("Erro ao enviar código de confirmação:", erroEmail);

              return res.status(502).json({
                erro: "Não foi possível enviar o e-mail. Tente novamente.",
              });
            }
          },
        );
      },
    );
  });
};

const criarSessaoConvidado = (convidadoId, eventoId, callback) => {
  const accessToken = crypto.randomBytes(32).toString("hex");
  const refreshToken = crypto.randomBytes(32).toString("hex");

  const accessTokenHash = crypto
    .createHash("sha256")
    .update(accessToken)
    .digest("hex");

  const refreshTokenHash = crypto
    .createHash("sha256")
    .update(refreshToken)
    .digest("hex");

  const sql = `
        INSERT INTO convidado_sessao (
            convidado_id,
            evento_id,
            access_token_hash,
            refresh_token_hash,
            access_expira_em,
            refresh_expira_em
        )
        VALUES (
            ?, ?, ?, ?,
            DATE_ADD(NOW(), INTERVAL 15 MINUTE),
            DATE_ADD(NOW(), INTERVAL 30 DAY)
        )
    `;

  conexao.query(
    sql,
    [convidadoId, eventoId, accessTokenHash, refreshTokenHash],
    (erro, resultado) => {
      if (erro) {
        console.error("Erro ao criar sessão:", erro);
        return callback(erro);
      }

      return callback(null, {
        sessao_id: resultado.insertId,
        access_token: accessToken,
        refresh_token: refreshToken,
        token_type: "Bearer",
        expires_in: 900,
        refresh_expires_in: 2592000,
      });
    },
  );
};

const validarCodigoConvidado = (req, res) => {
  const { codigo_evento, email, codigo } = req.body;

  if (!codigo_evento || !email || !codigo) {
    return res.status(400).json({
      erro: "Informe o código do evento, e-mail e código de confirmação.",
    });
  }

  const codigoEvento = codigo_evento.trim().toUpperCase();
  const emailLimpo = email.trim().toLowerCase();
  const codigoLimpo = String(codigo).trim();

  if (!/^\d{6}$/.test(codigoLimpo)) {
    return res.status(400).json({
      erro: "O código deve conter 6 números.",
    });
  }

  if (!process.env.EMAIL_CODE_SECRET) {
    return res.status(500).json({
      erro: "Serviço de verificação indisponível.",
    });
  }

  const sqlEvento = `
        SELECT
            evento_id,
            data_evento,
            CASE
                WHEN data_evento IS NULL THEN 1
                WHEN DATE(
                    CONVERT_TZ(UTC_TIMESTAMP(), '+00:00', '-03:00')
                ) > DATE_ADD(data_evento, INTERVAL 10 DAY)
                THEN 1
                ELSE 0
            END AS evento_encerrado
        FROM evento
        WHERE codigo_evento = ?
    `;

  conexao.query(sqlEvento, [codigoEvento], (erro, eventos) => {
    if (erro) {
      console.error(erro);
      return res.status(500).json({
        erro: "Erro ao verificar evento.",
      });
    }

    if (eventos.length === 0) {
      return res.status(404).json({
        erro: "Evento não encontrado.",
      });
    }

    const evento = eventos[0];

    if (evento.evento_encerrado === 1) {
      return res.status(403).json({
        erro: "O prazo de acesso a este evento foi encerrado.",
      });
    }

    const eventoId = evento.evento_id;

    const sqlVerificacao = `
            SELECT
                nome,
                codigo_hash,
                tentativas,
                (expira_em <= NOW()) AS expirado,
                (bloqueado_ate > NOW()) AS bloqueado,
                (usado_em IS NOT NULL) AS utilizado
            FROM convidado_verificacao
            WHERE evento_id = ? AND email = ?
        `;

    conexao.query(
      sqlVerificacao,
      [eventoId, emailLimpo],
      (erroConsulta, verificacoes) => {
        if (erroConsulta) {
          console.error(erroConsulta);
          return res.status(500).json({
            erro: "Erro ao consultar código de confirmação.",
          });
        }

        if (verificacoes.length === 0) {
          return res.status(404).json({
            erro: "Nenhum código de confirmação encontrado.",
          });
        }

        const verificacao = verificacoes[0];

        if (verificacao.utilizado) {
          return res.status(400).json({
            erro: "Este código já foi utilizado. Solicite outro.",
          });
        }

        if (verificacao.bloqueado) {
          return res.status(429).json({
            erro: "Muitas tentativas. Solicite um novo código mais tarde.",
          });
        }

        if (verificacao.expirado) {
          return res.status(400).json({
            erro: "Código expirado. Solicite um novo código.",
          });
        }

        const codigoHash = crypto
          .createHmac("sha256", process.env.EMAIL_CODE_SECRET)
          .update(`${eventoId}:${emailLimpo}:${codigoLimpo}`)
          .digest("hex");

        const hashInformado = Buffer.from(codigoHash, "hex");
        const hashArmazenado = Buffer.from(verificacao.codigo_hash, "hex");

        const codigoCorreto =
          hashInformado.length === hashArmazenado.length &&
          crypto.timingSafeEqual(hashInformado, hashArmazenado);

        if (!codigoCorreto) {
          const sqlTentativa = `
                        UPDATE convidado_verificacao
                        SET
                            bloqueado_ate = CASE
                                WHEN tentativas >= 4
                                THEN DATE_ADD(NOW(), INTERVAL 15 MINUTE)
                                ELSE bloqueado_ate
                            END,
                            tentativas = tentativas + 1
                        WHERE evento_id = ?
                          AND email = ?
                          AND expira_em > NOW()
                          AND usado_em IS NULL
                    `;

          return conexao.query(
            sqlTentativa,
            [eventoId, emailLimpo],
            (erroTentativa) => {
              if (erroTentativa) {
                console.error(erroTentativa);
                return res.status(500).json({
                  erro: "Erro ao registrar tentativa.",
                });
              }

              return res.status(401).json({
                erro: "Código incorreto.",
                mensagem: "Confira o código e tente novamente.",
              });
            },
          );
        }

        const sqlUtilizar = `
                    UPDATE convidado_verificacao
                    SET usado_em = NOW()
                    WHERE evento_id = ?
                      AND email = ?
                      AND codigo_hash = ?
                      AND expira_em > NOW()
                      AND usado_em IS NULL
                      AND tentativas < 5
                      AND (
                          bloqueado_ate IS NULL
                          OR bloqueado_ate <= NOW()
                      )
                `;

        conexao.query(
          sqlUtilizar,
          [eventoId, emailLimpo, codigoHash],
          (erroUtilizar, resultado) => {
            if (erroUtilizar) {
              console.error(erroUtilizar);
              return res.status(500).json({
                erro: "Erro ao validar código.",
              });
            }

            if (resultado.affectedRows === 0) {
              return res.status(400).json({
                erro: "Código inválido, expirado ou já utilizado.",
              });
            }

            const sqlBuscarConvidado = `
                            SELECT convidado_id, nome, email
                            FROM convidado
                            WHERE evento_id = ? AND email = ?
                            LIMIT 1
                        `;

            conexao.query(
              sqlBuscarConvidado,
              [eventoId, emailLimpo],
              (erroConvidado, convidados) => {
                if (erroConvidado) {
                  console.error(erroConvidado);
                  return res.status(500).json({
                    erro: "Erro ao localizar convidado.",
                  });
                }

                if (convidados.length === 0) {
                  const sqlCadastrar = `
                                        INSERT INTO convidado (
                                            nome,
                                            email,
                                            evento_id,
                                            status_confirmacao
                                        )
                                        VALUES (?, ?, ?, 'PENDENTE')
                                    `;

                  return conexao.query(
                    sqlCadastrar,
                    [verificacao.nome, emailLimpo, eventoId],
                    (erroCadastro, resultadoCadastro) => {
                      if (erroCadastro) {
                        console.error(erroCadastro);
                        return res.status(500).json({
                          erro: "Erro ao cadastrar convidado.",
                        });
                      }

                      return criarSessaoConvidado(
                        resultadoCadastro.insertId,
                        eventoId,
                        (erroSessao, sessao) => {
                          if (erroSessao) {
                            return res.status(500).json({
                              erro: "E-mail confirmado, mas não foi possível criar a sessão.",
                            });
                          }

                          return res.status(200).json({
                            mensagem:
                              "E-mail confirmado e convidado cadastrado com sucesso.",
                            convidado_id: resultadoCadastro.insertId,
                            evento_id: eventoId,
                            sessao: sessao,
                          });
                        },
                      );
                    },
                  );
                }

                return criarSessaoConvidado(
                  convidados[0].convidado_id,
                  eventoId,
                  (erroSessao, sessao) => {
                    if (erroSessao) {
                      return res.status(500).json({
                        erro: "E-mail confirmado, mas não foi possível criar a sessão.",
                      });
                    }

                    return res.status(200).json({
                      mensagem: "E-mail confirmado com sucesso.",
                      convidado_id: convidados[0].convidado_id,
                      evento_id: eventoId,
                      sessao: sessao,
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  });
};

const renovarSessaoConvidado = (req, res) => {
  const { refresh_token } = req.body;

  if (!refresh_token || typeof refresh_token !== "string") {
    return res.status(400).json({
      erro: "Refresh token não informado.",
    });
  }

  const refreshTokenHash = crypto
    .createHash("sha256")
    .update(refresh_token)
    .digest("hex");

  const sqlBuscar = `
        SELECT
            s.sessao_id,
            s.evento_id,
            s.convidado_id,
            e.data_evento,
            CASE
                WHEN e.data_evento IS NULL THEN 1
                WHEN DATE(
                    CONVERT_TZ(UTC_TIMESTAMP(), '+00:00', '-03:00')
                ) > DATE_ADD(e.data_evento, INTERVAL 10 DAY)
                THEN 1
                ELSE 0
            END AS evento_encerrado
        FROM convidado_sessao s
        INNER JOIN evento e ON e.evento_id = s.evento_id
        WHERE s.refresh_token_hash = ?
          AND s.revogado_em IS NULL
          AND s.refresh_expira_em > NOW()
        LIMIT 1
    `;

  conexao.query(sqlBuscar, [refreshTokenHash], (erro, sessoes) => {
    if (erro) {
      console.error("Erro ao buscar sessão:", erro);
      return res.status(500).json({
        erro: "Erro ao renovar sessão.",
      });
    }

    if (sessoes.length === 0) {
      return res.status(401).json({
        erro: "Sessão inválida ou expirada. Faça o acesso novamente.",
      });
    }

    const sessao = sessoes[0];

    if (sessao.evento_encerrado === 1) {
      return res.status(403).json({
        erro: "O prazo de acesso a este evento foi encerrado.",
      });
    }

    const novoAccessToken = crypto.randomBytes(32).toString("hex");
    const novoRefreshToken = crypto.randomBytes(32).toString("hex");

    const novoAccessHash = crypto
      .createHash("sha256")
      .update(novoAccessToken)
      .digest("hex");

    const novoRefreshHash = crypto
      .createHash("sha256")
      .update(novoRefreshToken)
      .digest("hex");

    const sqlAtualizar = `
            UPDATE convidado_sessao
            SET
                access_token_hash = ?,
                refresh_token_hash = ?,
                access_expira_em = DATE_ADD(NOW(), INTERVAL 15 MINUTE),
                refresh_expira_em = DATE_ADD(NOW(), INTERVAL 30 DAY)
            WHERE sessao_id = ?
              AND refresh_token_hash = ?
              AND revogado_em IS NULL
              AND refresh_expira_em > NOW()
        `;

    conexao.query(
      sqlAtualizar,
      [novoAccessHash, novoRefreshHash, sessao.sessao_id, refreshTokenHash],
      (erroAtualizar, resultado) => {
        if (erroAtualizar) {
          console.error("Erro ao atualizar sessão:", erroAtualizar);
          return res.status(500).json({
            erro: "Não foi possível renovar a sessão.",
          });
        }

        if (resultado.affectedRows === 0) {
          return res.status(401).json({
            erro: "Refresh token inválido ou já utilizado.",
          });
        }

        return res.status(200).json({
          mensagem: "Sessão renovada com sucesso.",
          sessao: {
            access_token: novoAccessToken,
            refresh_token: novoRefreshToken,
            token_type: "Bearer",
            expires_in: 900,
            refresh_expires_in: 2592000,
          },
        });
      },
    );
  });
};

const logoutConvidado = (req, res) => {
  const { refresh_token } = req.body;

  if (!refresh_token || typeof refresh_token !== "string") {
    return res.status(400).json({
      erro: "Refresh token não informado.",
    });
  }

  const refreshTokenHash = crypto
    .createHash("sha256")
    .update(refresh_token)
    .digest("hex");

  const sql = `
        UPDATE convidado_sessao
        SET revogado_em = NOW()
        WHERE refresh_token_hash = ?
          AND revogado_em IS NULL
    `;

  conexao.query(sql, [refreshTokenHash], (erro, resultado) => {
    if (erro) {
      console.error("Erro ao encerrar sessão:", erro);
      return res.status(500).json({
        erro: "Erro ao encerrar sessão.",
      });
    }

    if (resultado.affectedRows === 0) {
      return res.status(401).json({
        erro: "Sessão não encontrada ou já encerrada.",
      });
    }

    return res.status(200).json({
      mensagem: "Sessão encerrada com sucesso.",
    });
  });
};

module.exports = {
  cadastrarConvidado,
  cadastrarConvidadoPublico,
  buscarConvitePorToken,
  responderConvite,
  listarConvidadosPorEvento,
  alterarStatusConvidados,
  excluirConvidado,
  enviarCodigoConvidado,
  validarCodigoConvidado,
  renovarSessaoConvidado,
  logoutConvidado,
};
