
const conexao = require('../config/db');

const {
  descriptografarToken
} = require('../services/mercadoPagoCrypto');

const MP_API_URL = 'https://api.mercadopago.com';

const consultarBanco = (sql, parametros = []) => {
  return new Promise((resolve, reject) => {
    conexao.query(sql, parametros, (erro, resultado) => {
      if (erro) return reject(erro);
      resolve(resultado);
    });
  });
};

const reconciliarPagamento = async (req, res) => {
  const pagamentoId = Number(req.params.pagamentoId);

  if (!Number.isSafeInteger(pagamentoId) || pagamentoId <= 0) {
    return res.status(400).json({
      erro: 'Identificador de pagamento inválido.'
    });
  }

  // IMPORTANTE:
  // Este campo precisa corresponder ao que o
  // authMiddleware realmente coloca em req.
  const administradorId = req.usuario?.usuario_id;

  if (!administradorId) {
    return res.status(401).json({
      erro: 'Administrador não autenticado.'
    });
  }

  try {
    // O JOIN com evento garante que o administrador
    // só acesse pagamentos dos próprios eventos.
    const registros = await consultarBanco(
      `
      SELECT
        pg.pagamento_id,
        pg.valor_pagamento,
        pg.status_pagamento,
        pg.gateway_pagamento,
        pg.mp_payment_id,
        pg.external_reference,
        mc.mp_user_id,
        mc.access_token_enc
      FROM pagamento pg
      INNER JOIN presente p
        ON p.presente_id = pg.presente_id
      INNER JOIN evento e
        ON e.evento_id = p.evento_id
      INNER JOIN mercadopago_conexao mc
        ON mc.usuario_id = e.usuario_id
      WHERE pg.pagamento_id = ?
        AND e.usuario_id = ?
        AND pg.gateway_pagamento = 'MERCADO_PAGO'
      LIMIT 1
      `,
      [pagamentoId, administradorId]
    );

    if (registros.length === 0) {
      return res.status(404).json({
        erro: 'Pagamento não encontrado.'
      });
    }

    const registro = registros[0];

    if (
      !registro.mp_payment_id ||
      !/^\d+$/.test(String(registro.mp_payment_id))
    ) {
      return res.status(409).json({
        erro: 'Pagamento sem identificador válido no Mercado Pago.'
      });
    }

    if (!registro.external_reference) {
      return res.status(409).json({
        erro: 'Pagamento sem referência externa.'
      });
    }

    const token = descriptografarToken(
      registro.access_token_enc
    );

    const resposta = await fetch(
      `${MP_API_URL}/v1/payments/${registro.mp_payment_id}`,
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`
        },
        signal: AbortSignal.timeout(15000)
      }
    );

    if (!resposta.ok) {
      console.error(
        'Reconciliação: consulta Mercado Pago falhou:',
        resposta.status
      );

      return res.status(502).json({
        erro: 'Não foi possível consultar o Mercado Pago.'
      });
    }

    const dados = await resposta.json();

    const valorEsperado = Math.round(
      Number(registro.valor_pagamento) * 100
    );

    const valorRecebido = Math.round(
      Number(dados.transaction_amount) * 100
    );

    // Confere os dados do pagamento antes de
    // modificar qualquer registro.
    const pagamentoValido =
      String(dados.id) === String(registro.mp_payment_id) &&
      String(dados.collector_id) === String(registro.mp_user_id) &&
      dados.currency_id === 'BRL' &&
      dados.external_reference === registro.external_reference &&
      Number.isSafeInteger(valorEsperado) &&
      Number.isSafeInteger(valorRecebido) &&
      valorEsperado > 0 &&
      valorEsperado === valorRecebido;

    if (!pagamentoValido) {
      console.error(
        'Reconciliação: pagamento não corresponde ao registro.'
      );

      return res.status(409).json({
        erro: 'Os dados do Mercado Pago não correspondem ao pagamento.'
      });
    }

    if (dados.status === 'approved') {
      await consultarBanco(
        `
        UPDATE pagamento
        SET status_pagamento = 'APROVADO'
        WHERE pagamento_id = ?
          AND status_pagamento = 'PENDENTE'
          AND mp_payment_id = ?
        `,
        [pagamentoId, String(dados.id)]
      );
    }

    // Consulta novamente para devolver o estado
    // efetivamente persistido no MySQL.
    const atualizados = await consultarBanco(
      `
      SELECT
        pagamento_id,
        valor_pagamento,
        status_pagamento,
        mp_payment_id,
        atualizado_em
      FROM pagamento
      WHERE pagamento_id = ?
      LIMIT 1
      `,
      [pagamentoId]
    );

    return res.status(200).json({
      mensagem: 'Pagamento consultado com sucesso.',
      status_mercado_pago: dados.status,
      pagamento: atualizados[0]
    });

  } catch (erro) {
    console.error(
      'Erro ao reconciliar pagamento:',
      erro.message
    );

    return res.status(500).json({
      erro: 'Não foi possível reconciliar o pagamento.'
    });
  }
};

module.exports = {
  reconciliarPagamento
};
