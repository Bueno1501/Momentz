const crypto = require("node:crypto");
const conexao = require("../config/db");

const { descriptografarToken } = require("../services/mercadoPagoCrypto");

const MP_API_URL = "https://api.mercadopago.com";

const WEBHOOK_URL =
  "https://momentz-production.up.railway.app/pagamentos/webhook";

const consultarBanco = (sql, parametros = []) =>
  new Promise((resolve, reject) => {
    conexao.query(sql, parametros, (erro, resultado) => {
      if (erro) return reject(erro);
      resolve(resultado);
    });
  });

const criarPagamentoPix = async (req, res) => {
  const { presente_id, mensagem, email_pagador, idempotency_key } =
    req.body || {};

  const eventoId = req.convidado?.evento_id;
  const convidadoId = req.convidado?.convidado_id;
  const presenteId = Number(presente_id);

  if (!eventoId || !convidadoId) {
    return res.status(401).json({
      erro: "Sessão do convidado inválida.",
    });
  }

  if (!Number.isSafeInteger(presenteId) || presenteId <= 0) {
    return res.status(400).json({
      erro: "Presente inválido.",
    });
  }

  const email =
    typeof email_pagador === "string" ? email_pagador.trim().toLowerCase() : "";

  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({
      erro: "Informe um e-mail válido.",
    });
  }

  if (mensagem != null && typeof mensagem !== "string") {
    return res.status(400).json({
      erro: "Mensagem inválida.",
    });
  }

  const mensagemLimpa = (mensagem || "").trim();

  if (mensagemLimpa.length > 300) {
    return res.status(400).json({
      erro: "A mensagem deve ter no máximo 300 caracteres.",
    });
  }

  if (
    typeof idempotency_key !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
      idempotency_key,
    )
  ) {
    return res.status(400).json({
      erro: "Informe uma chave de idempotência UUID válida.",
    });
  }

  const referencia = idempotency_key.toLowerCase();

  try {
    const presentes = await consultarBanco(
      `
      SELECT
        p.presente_id,
        p.nome_presente,
        p.valor,
        e.usuario_id AS administrador_id
      FROM presente p
      INNER JOIN evento e
        ON e.evento_id = p.evento_id
      WHERE p.presente_id = ?
        AND p.evento_id = ?
        AND p.tipo_presente = 'MOMENTZ'
        AND p.status_produto = 'DISPONIVEL'
      LIMIT 1
      `,
      [presenteId, eventoId],
    );

    if (!presentes.length) {
      return res.status(404).json({
        erro: "Presente não encontrado ou indisponível.",
      });
    }

    const presente = presentes[0];
    const valor = Number(presente.valor);
    const centavos = Math.round(valor * 100);

    if (
      !Number.isFinite(valor) ||
      centavos <= 0 ||
      Math.abs(valor * 100 - centavos) > 0.00001
    ) {
      return res.status(400).json({
        erro: "Valor do presente inválido.",
      });
    }

    const conexoes = await consultarBanco(
      `
      SELECT
        mp_user_id,
        access_token_enc,
        token_expira_em
      FROM mercadopago_conexao
      WHERE usuario_id = ?
      LIMIT 1
      `,
      [presente.administrador_id],
    );

    if (!conexoes.length) {
      return res.status(409).json({
        erro: "Administrador sem conexão Mercado Pago.",
      });
    }

    const conta = conexoes[0];

    if (
      !conta.token_expira_em ||
      new Date(conta.token_expira_em).getTime() <= Date.now() + 60000
    ) {
      return res.status(409).json({
        erro: "A conexão Mercado Pago precisa ser renovada.",
      });
    }

    const token = descriptografarToken(conta.access_token_enc);

    // A referência é única no banco.
    // Repetir a tentativa reutiliza o mesmo registro.

    await consultarBanco(
      `
      INSERT INTO pagamento (
        valor_pagamento,
        status_pagamento,
        gateway_pagamento,
        presente_id,
        convidado_id,
        external_reference,
        mensagem
      )
      VALUES (
        ?, 'PENDENTE', 'MERCADO_PAGO',
        ?, ?, ?, ?
      )
      ON DUPLICATE KEY UPDATE
        pagamento_id = pagamento_id
      `,
      [
        valor.toFixed(2),
        presenteId,
        convidadoId,
        referencia,
        mensagemLimpa || null,
      ],
    );

    const registros = await consultarBanco(
      `
      SELECT
        pagamento_id,
        presente_id,
        convidado_id,
        valor_pagamento,
        status_pagamento,
        mp_payment_id,
        mensagem
      FROM pagamento
      WHERE external_reference = ?
      LIMIT 1
      `,
      [referencia],
    );

    const pagamento = registros[0];

    if (
      !pagamento ||
      Number(pagamento.presente_id) !== presenteId ||
      Number(pagamento.convidado_id) !== Number(convidadoId) ||
      Math.round(Number(pagamento.valor_pagamento) * 100) !== centavos ||
      (pagamento.mensagem || "") !== mensagemLimpa
    ) {
      return res.status(409).json({
        erro: "Esta chave já pertence a outra tentativa de pagamento.",
      });
    }

    if (pagamento.status_pagamento !== "PENDENTE") {
      return res.status(409).json({
        erro: "Este pagamento não está mais pendente.",
      });
    }

    const resposta = await fetch(`${MP_API_URL}/v1/payments`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        "X-Idempotency-Key": referencia,
      },
      body: JSON.stringify({
        transaction_amount: valor,
        description: `MOMENTZ - ${presente.nome_presente}`,
        payment_method_id: "pix",
        external_reference: referencia,
        notification_url: `${WEBHOOK_URL}?source_news=webhooks`,
        payer: {
          email,
        },
      }),
      signal: AbortSignal.timeout(15000),
    });

    const dados = await resposta.json();

    if (!resposta.ok) {
      console.error("Erro Mercado Pago Pix:", {
        status: resposta.status,
        mensagem: dados.message || dados.error,
      });

      return res.status(502).json({
        erro: "Não foi possível gerar o Pix. Tente novamente com a mesma chave.",
      });
    }

    if (
      !dados.id ||
      String(dados.collector_id) !== String(conta.mp_user_id) ||
      String(dados.external_reference) !== referencia ||
      dados.currency_id !== "BRL" ||
      Math.round(Number(dados.transaction_amount) * 100) !== centavos
    ) {
      console.error("Resposta Pix não corresponde ao pagamento esperado.");

      return res.status(502).json({
        erro: "Não foi possível validar a cobrança Pix.",
      });
    }

    const transacao = dados.point_of_interaction?.transaction_data;

    // Salvar o ID antes de verificar os dados de exibição.
    // Assim a cobrança pode ser localizada mesmo se
    // o QR Code não estiver disponível na resposta.

    const atualizacao = await consultarBanco(
      `
      UPDATE pagamento
      SET mp_payment_id = ?
      WHERE pagamento_id = ?
        AND (mp_payment_id IS NULL OR mp_payment_id = ?)
      `,
      [String(dados.id), pagamento.pagamento_id, String(dados.id)],
    );

    if (atualizacao.affectedRows !== 1) {
      console.error(
        "Conflito ao associar pagamento Mercado Pago:",
        pagamento.pagamento_id,
      );

      return res.status(409).json({
        erro: "Não foi possível associar a cobrança ao pagamento.",
      });
    }

    if (!transacao?.qr_code) {
      return res.status(502).json({
        erro: "A cobrança foi registrada, mas o QR Code não está disponível.",
      });
    }

    return res.status(201).json({
      mensagem: "Pix gerado com sucesso.",
      pagamento_id: pagamento.pagamento_id,
      status: dados.status,
      valor,
      pix: {
        qr_code: transacao.qr_code,
        qr_code_base64: transacao.qr_code_base64 || null,
        ticket_url: transacao.ticket_url || null,
      },
    });
  } catch (erro) {
    console.error("Erro ao gerar Pix:", erro.message);

    return res.status(500).json({
      erro: "Falha ao processar o Pix. Reutilize a mesma chave ao tentar novamente.",
    });
  }
};

module.exports = {
  criarPagamentoPix,
};
