
const crypto = require("crypto");

const conexao = require("../config/db");

const { descriptografarToken } = require("../services/mercadoPagoCrypto");

const MP_API_URL = "https://api.mercadopago.com";

const FRONTEND_URL = (
  process.env.FRONTEND_URL || "https://momentz-production-19.up.railway.app"
).replace(/\/$/, "");

const consultarBanco = (sql, parametros = []) => {
  return new Promise((resolve, reject) => {
    conexao.query(sql, parametros, (erro, resultado) => {
      if (erro) return reject(erro);
      resolve(resultado);
    });
  });
};

// ============================================================
// CRIAR CHECKOUT DO PRESENTE
// ============================================================

const criarCheckoutPresente = async (req, res) => {
  const { presente_id, mensagem } = req.body || {};

  if (!req.convidado?.evento_id) {
    return res.status(401).json({
      erro: "Sessão do convidado inválida.",
    });
  }

  const presenteId = Number(presente_id);

  if (!Number.isSafeInteger(presenteId) || presenteId <= 0) {
    return res.status(400).json({
      erro: "Identificador do presente inválido.",
    });
  }

  if (mensagem != null && typeof mensagem !== "string") {
    return res.status(400).json({
      erro: "A mensagem deve ser um texto.",
    });
  }

  const mensagemLimpa = (mensagem || "").trim();

  if (mensagemLimpa.length > 300) {
    return res.status(400).json({
      erro: "A mensagem deve ter no máximo 300 caracteres.",
    });
  }

  try {
    // O evento vem da sessão autenticada do convidado.
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
      [presenteId, req.convidado.evento_id],
    );

    if (presentes.length === 0) {
      return res.status(404).json({
        erro: "Presente não encontrado ou indisponível.",
      });
    }

    const presente = presentes[0];
    const valor = Number(presente.valor);

    if (!Number.isFinite(valor) || valor <= 0) {
      return res.status(400).json({
        erro: "O presente possui um valor inválido.",
      });
    }

    // Identifica a conta Mercado Pago do administrador.
    const conexoes = await consultarBanco(
      `
        SELECT
          access_token_enc,
          mp_user_id,
          token_expira_em
        FROM mercadopago_conexao
        WHERE usuario_id = ?
        LIMIT 1
      `,
      [presente.administrador_id],
    );

    if (conexoes.length === 0) {
      return res.status(409).json({
        erro: "O administrador ainda não conectou o Mercado Pago.",
      });
    }

    const conta = conexoes[0];

    if (
      !conta.token_expira_em ||
      new Date(conta.token_expira_em).getTime() <= Date.now() + 60000
    ) {
      return res.status(409).json({
        erro: "A conexão Mercado Pago do administrador precisa ser renovada.",
      });
    }

    const accessToken = descriptografarToken(
      conta.access_token_enc
    );

    // Referência única para identificar a tentativa.
    const referencia = crypto.randomUUID();

    const resultado = await consultarBanco(
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
        VALUES (?, 'PENDENTE', 'MERCADO_PAGO', ?, ?, ?, ?)
      `,
      [
        valor.toFixed(2),
        presenteId,
        req.convidado.convidado_id || null,
        referencia,
        mensagemLimpa || null,
      ],
    );

    const pagamentoId = resultado.insertId;

    const retornoBase = `${FRONTEND_URL}/`;

    // Preferência do Checkout Pro.
    const preferencia = {
      items: [
        {
          id: String(presenteId),
          title: presente.nome_presente,
          quantity: 1,
          currency_id: "BRL",
          unit_price: valor,
        },
      ],

      external_reference: referencia,

      notification_url:
        "https://momentz-production.up.railway.app/pagamentos/webhook",

      back_urls: {
        success: `${retornoBase}?momentz_pagamento=sucesso`,
        failure: `${retornoBase}?momentz_pagamento=falha`,
        pending: `${retornoBase}?momentz_pagamento=pendente`,
      },

      auto_return: "approved",
    };

    // Cria a preferência na conta OAuth do administrador.
    const resposta = await fetch(
      `${MP_API_URL}/checkout/preferences`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
          "X-Idempotency-Key": referencia,
        },
        body: JSON.stringify(preferencia),
        signal: AbortSignal.timeout(15000),
      }
    );

    const dados = await resposta.json();

    if (!resposta.ok) {
      console.error(
        "Falha ao criar preferência Mercado Pago:",
        resposta.status,
        dados.error || dados.message
      );

      return res.status(502).json({
        erro: "Não foi possível iniciar o checkout.",
      });
    }

    if (!dados.id || !dados.init_point) {
      return res.status(502).json({
        erro: "O Mercado Pago não retornou um checkout válido.",
      });
    }

    // Confere se a preferência pertence ao recebedor esperado.
    if (
      !dados.collector_id ||
      String(dados.collector_id) !== String(conta.mp_user_id)
    ) {
      console.error(
        "A preferência retornou uma conta recebedora inesperada."
      );

      return res.status(502).json({
        erro: "Não foi possível validar o recebedor.",
      });
    }

    await consultarBanco(
      `
        UPDATE pagamento
        SET mp_preference_id = ?
        WHERE pagamento_id = ?
          AND status_pagamento = 'PENDENTE'
      `,
      [String(dados.id), pagamentoId],
    );

    return res.status(201).json({
      mensagem: "Checkout criado com sucesso.",
      pagamento_id: pagamentoId,
      checkout_url: dados.init_point,
    });

  } catch (erro) {
    console.error(
      "Erro ao criar checkout:",
      erro.message
    );

    return res.status(500).json({
      erro: "Não foi possível preparar o pagamento.",
    });
  }
};




const assinaturaWebhookValida = (req) => {
  const segredo = process.env.MP_WEBHOOK_SECRET;
  const assinatura = req.get("x-signature");
  const requestId = req.get("x-request-id");

  // Preserva o valor original recebido na URL.
  const dataId = req.query["data.id"];

  const rejeitar = (motivo) => {
    console.warn("Webhook: assinatura rejeitada:", motivo);
    return false;
  };

  if (!segredo || typeof segredo !== "string") {
    return rejeitar("segredo não configurado");
  }

  if (!assinatura || typeof assinatura !== "string") {
    return rejeitar("x-signature ausente");
  }

  const partes = {};

  for (const parte of assinatura.split(",")) {
    const indice = parte.indexOf("=");

    if (indice < 1) {
      return rejeitar("formato de assinatura inválido");
    }

    partes[parte.slice(0, indice).trim()] =
      parte.slice(indice + 1).trim();
  }

  const { ts, v1 } = partes;

  if (!/^\d{10,16}$/.test(ts || "")) {
    return rejeitar("timestamp inválido");
  }

  if (!/^[a-f0-9]{64}$/i.test(v1 || "")) {
    return rejeitar("hash inválido");
  }

  const numeroTs = Number(ts);
  const timestampMs =
    numeroTs < 100000000000
      ? numeroTs * 1000
      : numeroTs;

  if (!Number.isFinite(timestampMs)) {
    return rejeitar("timestamp não numérico");
  }

  // Mantemos proteção contra timestamps muito futuros.
  // Não rejeitamos automaticamente reentregas antigas,
  // pois a autenticidade depende da assinatura HMAC.
  if (timestampMs > Date.now() + 5 * 60 * 1000) {
    return rejeitar("timestamp no futuro");
  }

  // Montagem do manifesto conforme a documentação.
  let manifesto = "";

  if (typeof dataId === "string" && dataId.trim()) {
    manifesto += `id:${dataId.toLowerCase()};`;
  }

  if (typeof requestId === "string" && requestId) {
    manifesto += `request-id:${requestId};`;
  }

  manifesto += `ts:${ts};`;

  const calculada = crypto
    .createHmac("sha256", segredo)
    .update(manifesto)
    .digest();

  const recebida = Buffer.from(v1, "hex");

if (
  recebida.length !== calculada.length ||
  !crypto.timingSafeEqual(recebida, calculada)
) {
  console.warn("Webhook: diagnóstico HMAC:", {
    dataIdQuery: dataId ?? null,
    dataIdBody: req.body?.data?.id ?? null,
    tipoQuery: req.query.type ?? null,
    tipoBody: req.body?.type ?? null,
    requestIdPresente: Boolean(requestId),
    timestampDigitos: ts.length,
    segredoConfigurado: Boolean(segredo),
    segredoComprimento: segredo.length,
    urlRecebida: req.originalUrl
  });

  return rejeitar("HMAC não corresponde");
}

  return true;
};


// ============================================================
// RECEBER WEBHOOK DO MERCADO PAGO
// ============================================================

const receberWebhookMercadoPago = async (req, res) => {
  if (!assinaturaWebhookValida(req)) {
    return res.sendStatus(401);
  }

  const tipo = req.query.type || req.body?.type;

  if (tipo !== "payment") {
    return res.sendStatus(200);
  }

  const paymentId = req.query["data.id"] ?? req.body?.data?.id;

  if (!/^\d+$/.test(paymentId)) {
    return res.sendStatus(400);
  }

  try {
    // Identifica a conta Mercado Pago que recebeu
    // a notificação.
    const userIdNotificado = req.body?.user_id;

    let conta = null;

    if (
      userIdNotificado != null &&
      /^\d+$/.test(String(userIdNotificado))
    ) {
      const contas = await consultarBanco(
        `
          SELECT
            usuario_id,
            mp_user_id,
            access_token_enc
          FROM mercadopago_conexao
          WHERE mp_user_id = ?
          LIMIT 1
        `,
        [String(userIdNotificado)],
      );

      conta = contas[0] || null;
    }

    // Notificações repetidas podem já ter
    // o ID do pagamento registrado.
    if (!conta) {
      const contas = await consultarBanco(
        `
          SELECT
            mc.usuario_id,
            mc.mp_user_id,
            mc.access_token_enc
          FROM pagamento pg
          INNER JOIN presente p
            ON p.presente_id = pg.presente_id
          INNER JOIN evento e
            ON e.evento_id = p.evento_id
          INNER JOIN mercadopago_conexao mc
            ON mc.usuario_id = e.usuario_id
          WHERE pg.mp_payment_id = ?
          LIMIT 1
        `,
        [paymentId],
      );

      conta = contas[0] || null;
    }

    if (!conta) {
      console.error(
        "Webhook: conta recebedora não identificada."
      );

      return res.sendStatus(503);
    }

    const token = descriptografarToken(
      conta.access_token_enc
    );

    // Consulta o pagamento diretamente na API oficial.
    const resposta = await fetch(
      `${MP_API_URL}/v1/payments/${paymentId}`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
        signal: AbortSignal.timeout(15000),
      }
    );

    if (!resposta.ok) {
      console.error(
        "Webhook: consulta do pagamento falhou:",
        resposta.status
      );

      return res.sendStatus(503);
    }

    const dados = await resposta.json();

    // Valida os dados retornados pelo Mercado Pago.
    if (
      String(dados.id) !== paymentId ||
      String(dados.collector_id) !== String(conta.mp_user_id) ||
      dados.currency_id !== "BRL" ||
      typeof dados.external_reference !== "string" ||
      !dados.external_reference
    ) {
      console.error(
        "Webhook: dados do pagamento incompatíveis com a conta."
      );

      return res.sendStatus(200);
    }

    // Localiza a tentativa original pelo external_reference.
    const registros = await consultarBanco(
      `
        SELECT
          pg.pagamento_id,
          pg.valor_pagamento,
          pg.status_pagamento,
          pg.mp_payment_id,
          mc.mp_user_id
        FROM pagamento pg
        INNER JOIN presente p
          ON p.presente_id = pg.presente_id
        INNER JOIN evento e
          ON e.evento_id = p.evento_id
        INNER JOIN mercadopago_conexao mc
          ON mc.usuario_id = e.usuario_id
        WHERE pg.external_reference = ?
          AND pg.gateway_pagamento = 'MERCADO_PAGO'
        LIMIT 1
      `,
      [dados.external_reference],
    );

    if (registros.length === 0) {
      console.error(
        "Webhook: referência desconhecida:",
        dados.external_reference
      );

      return res.sendStatus(200);
    }

    const registro = registros[0];

    // Compara os valores em centavos.
    const esperado = Math.round(
      Number(registro.valor_pagamento) * 100
    );

    const recebido = Math.round(
      Number(dados.transaction_amount) * 100
    );

    if (
      !Number.isSafeInteger(esperado) ||
      !Number.isSafeInteger(recebido) ||
      esperado <= 0 ||
      esperado !== recebido ||
      String(registro.mp_user_id) !== String(dados.collector_id) ||
      (
        registro.mp_payment_id &&
        String(registro.mp_payment_id) !== paymentId
      )
    ) {
      console.error(
        "Webhook: valor, recebedor ou ID de pagamento divergente."
      );

      return res.sendStatus(200);
    }


    if (dados.status === "approved") {


      await consultarBanco(
        `
          UPDATE pagamento
          SET
            status_pagamento = 'APROVADO',
            mp_payment_id = ?
          WHERE pagamento_id = ?
            AND status_pagamento = 'PENDENTE'
            AND (
              mp_payment_id IS NULL
              OR mp_payment_id = ?
            )
        `,
        [
          paymentId,
          registro.pagamento_id,
          paymentId,
        ],
      );

    } else if (
      dados.status === "pending" ||
      dados.status === "in_process"
    ) {

    } else {

      console.log(
        "Webhook: status recebido:",
        dados.status
      );
    }

    return res.sendStatus(200);

  } catch (erro) {
    console.error(
      "Webhook: erro ao processar:",
      erro.message
    );

    return res.sendStatus(500);
  }
};

module.exports = {
  criarCheckoutPresente,
  receberWebhookMercadoPago,
};
