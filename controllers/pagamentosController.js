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
  const { presente_id, mensagem, metodo_pagamento, idempotency_key } =
    req.body || {};

  const eventoId = req.convidado?.evento_id;
  const convidadoId = req.convidado?.convidado_id;
  const presenteId = Number(presente_id);

  // 1. Validar a sessão do convidado.
  if (!eventoId || !convidadoId) {
    return res.status(401).json({
      erro: "Sessão do convidado inválida.",
    });
  }

  // 2. Validar o presente.
  if (!Number.isSafeInteger(presenteId) || presenteId <= 0) {
    return res.status(400).json({
      erro: "Identificador do presente inválido.",
    });
  }

  // 3. Permitir apenas cartão ou boleto.
  const metodosPermitidos = ["CARTAO_CREDITO", "BOLETO"];

  if (!metodosPermitidos.includes(metodo_pagamento)) {
    return res.status(400).json({
      erro: "Escolha CARTAO_CREDITO ou BOLETO.",
    });
  }

  // 4. Validar a mensagem.
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

  // 5. Validar a chave de idempotência.
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

  if (typeof idempotency_key !== "string" || !uuidRegex.test(idempotency_key)) {
    return res.status(400).json({
      erro: "Informe uma chave de idempotência UUID válida.",
    });
  }

  const chave = idempotency_key.toLowerCase();

  // A modalidade faz parte da referência.
  const referencia = `${metodo_pagamento}:${chave}`;

  try {
    // 6. Buscar o presente no evento autenticado.
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

    // 7. Buscar a conexão Mercado Pago do administrador.
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

    if (!conexoes.length) {
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
        erro: "A conexão Mercado Pago precisa ser renovada.",
      });
    }

    const accessToken = descriptografarToken(conta.access_token_enc);

    // 8. Registrar ou reutilizar a tentativa.
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
        mp_preference_id,
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
        erro: "Esta chave já pertence a outra tentativa.",
      });
    }

    if (pagamento.status_pagamento !== "PENDENTE") {
      return res.status(409).json({
        erro: "Este pagamento não está mais pendente.",
      });
    }

    // 9. Se a preferência já existe, reutilizá-la.
    if (pagamento.mp_preference_id) {
      const consulta = await fetch(
        `${MP_API_URL}/checkout/preferences/${encodeURIComponent(
          pagamento.mp_preference_id,
        )}`,
        {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
          signal: AbortSignal.timeout(15000),
        },
      );

      if (!consulta.ok) {
        return res.status(502).json({
          erro: "Não foi possível recuperar o checkout existente.",
        });
      }

      const existente = await consulta.json();

      if (
        String(existente.id) !== String(pagamento.mp_preference_id) ||
        String(existente.collector_id) !== String(conta.mp_user_id) ||
        existente.external_reference !== referencia ||
        !existente.init_point
      ) {
        return res.status(502).json({
          erro: "Não foi possível validar o checkout existente.",
        });
      }

      return res.status(200).json({
        mensagem: "Checkout recuperado com sucesso.",
        pagamento_id: pagamento.pagamento_id,
        metodo_pagamento,
        checkout_url: existente.init_point,
      });
    }

    // 10. Configurar os métodos oferecidos.
    const tiposExcluidos =
      metodo_pagamento === "CARTAO_CREDITO"
        ? ["ticket", "bank_transfer", "debit_card", "prepaid_card", "atm"]
        : ["credit_card", "debit_card", "prepaid_card", "bank_transfer", "atm"];

    const paymentMethods = {
      excluded_payment_types: tiposExcluidos.map((id) => ({ id })),
    };

    if (metodo_pagamento === "CARTAO_CREDITO") {
      paymentMethods.installments = 12;
    }

    // 11. Criar a preferência.
    const retornoBase = `${FRONTEND_URL}/`;

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

      payment_methods: paymentMethods,

      notification_url:
        "https://momentz-production.up.railway.app/pagamentos/webhook?source_news=webhooks",

      back_urls: {
        success: `${retornoBase}?momentz_pagamento=sucesso`,
        failure: `${retornoBase}?momentz_pagamento=falha`,
        pending: `${retornoBase}?momentz_pagamento=pendente`,
      },

      auto_return: "approved",
    };

    // 12. Enviar ao Mercado Pago.
    const resposta = await fetch(`${MP_API_URL}/checkout/preferences`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "X-Idempotency-Key": chave,
      },
      body: JSON.stringify(preferencia),
      signal: AbortSignal.timeout(15000),
    });

    const dados = await resposta.json();

    if (!resposta.ok) {
      console.error("Erro Checkout Pro:", {
        status: resposta.status,
        mensagem: dados.message || dados.error,
      });

      return res.status(502).json({
        erro: "Não foi possível criar o checkout.",
      });
    }

    if (
      !dados.id ||
      !dados.init_point ||
      String(dados.collector_id) !== String(conta.mp_user_id) ||
      dados.external_reference !== referencia
    ) {
      console.error("Resposta de preferência incompatível.");

      return res.status(502).json({
        erro: "Não foi possível validar o checkout.",
      });
    }

    // 13. Associar a preferência ao pagamento.
    const atualizacao = await consultarBanco(
      `
      UPDATE pagamento
      SET mp_preference_id = ?
      WHERE pagamento_id = ?
        AND status_pagamento = 'PENDENTE'
        AND mp_preference_id IS NULL
      `,
      [String(dados.id), pagamento.pagamento_id],
    );

    if (atualizacao.affectedRows !== 1) {
      return res.status(409).json({
        erro: "Não foi possível associar a preferência.",
      });
    }

    // 14. Retornar o link para o Flutter.
    return res.status(201).json({
      mensagem: "Checkout criado com sucesso.",
      pagamento_id: pagamento.pagamento_id,
      metodo_pagamento,
      checkout_url: dados.init_point,
    });
  } catch (erro) {
    console.error("Erro ao criar Checkout Pro:", erro.message);

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

    partes[parte.slice(0, indice).trim()] = parte.slice(indice + 1).trim();
  }

  const { ts, v1 } = partes;

  if (!/^\d{10,16}$/.test(ts || "")) {
    return rejeitar("timestamp inválido");
  }

  if (!/^[a-f0-9]{64}$/i.test(v1 || "")) {
    return rejeitar("hash inválido");
  }

  const numeroTs = Number(ts);
  const timestampMs = numeroTs < 100000000000 ? numeroTs * 1000 : numeroTs;

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
      urlRecebida: req.originalUrl,
    });

    return rejeitar("HMAC não corresponde");
  }

  return true;
};

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

    if (userIdNotificado != null && /^\d+$/.test(String(userIdNotificado))) {
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
      console.error("Webhook: conta recebedora não identificada.");

      return res.sendStatus(503);
    }

    const token = descriptografarToken(conta.access_token_enc);

    // Consulta o pagamento diretamente na API oficial.
    const resposta = await fetch(`${MP_API_URL}/v1/payments/${paymentId}`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
      signal: AbortSignal.timeout(15000),
    });

    if (!resposta.ok) {
      console.error("Webhook: consulta do pagamento falhou:", resposta.status);

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
      console.error("Webhook: dados do pagamento incompatíveis com a conta.");

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
        dados.external_reference,
      );

      return res.sendStatus(200);
    }

    const registro = registros[0];

    // Compara os valores em centavos.
    const esperado = Math.round(Number(registro.valor_pagamento) * 100);

    const recebido = Math.round(Number(dados.transaction_amount) * 100);

    if (
      !Number.isSafeInteger(esperado) ||
      !Number.isSafeInteger(recebido) ||
      esperado <= 0 ||
      esperado !== recebido ||
      String(registro.mp_user_id) !== String(dados.collector_id) ||
      (registro.mp_payment_id && String(registro.mp_payment_id) !== paymentId)
    ) {
      console.error("Webhook: valor, recebedor ou ID de pagamento divergente.");

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
        [paymentId, registro.pagamento_id, paymentId],
      );
    } else if (dados.status === "pending" || dados.status === "in_process") {
    } else {
      console.log("Webhook: status recebido:", dados.status);
    }

    return res.sendStatus(200);
  } catch (erro) {
    console.error("Webhook: erro ao processar:", erro.message);

    return res.sendStatus(500);
  }
};

module.exports = {
  criarCheckoutPresente,
  receberWebhookMercadoPago,
};
