
const crypto = require('crypto');

const conexao = require('../config/db');

const {
    criptografarToken,
    descriptografarToken
} = require('../services/mercadoPagoCrypto');

const MP_AUTH_URL = 'https://auth.mercadopago.com/authorization';
const MP_TOKEN_URL = 'https://api.mercadopago.com/oauth/token';

const FRONTEND_URL = (
    process.env.FRONTEND_URL ||
    'https://momentz-production-19.up.railway.app'
).replace(/\/$/, '');

// Função auxiliar para utilizar o MySQL com async/await
const consultarBanco = (sql, parametros = []) => {
    return new Promise((resolve, reject) => {
        conexao.query(sql, parametros, (erro, resultados) => {
            if (erro) {
                return reject(erro);
            }

            resolve(resultados);
        });
    });
};

// Inicia a conexão com o Mercado Pago
const conectarMercadoPago = async (req, res) => {
    if (
        !req.usuario ||
        req.usuario.tipo_usuario !== 'Administrador' ||
        !req.usuario.usuario_id
    ) {
        return res.status(403).json({
            erro: 'Apenas administradores autenticados podem conectar uma conta.'
        });
    }

    const clientId = process.env.MP_CLIENT_ID;
    const redirectUri = process.env.MP_REDIRECT_URI;

    if (
        !clientId ||
        !redirectUri ||
        !process.env.MP_TOKEN_ENCRYPTION_KEY
    ) {
        return res.status(500).json({
            erro: 'Configurações do Mercado Pago não encontradas.'
        });
    }

    try {
        const state = crypto.randomBytes(32).toString('hex');

        const codeVerifier = crypto
            .randomBytes(32)
            .toString('base64url');

        const codeChallenge = crypto
            .createHash('sha256')
            .update(codeVerifier)
            .digest('base64url');

        const stateHash = crypto
            .createHash('sha256')
            .update(state)
            .digest('hex');

        const verifierCriptografado =
            criptografarToken(codeVerifier);

        const sql = `
            INSERT INTO mercadopago_oauth (
                usuario_id,
                state_hash,
                code_verifier_enc,
                expira_em
            )
            VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 10 MINUTE))
        `;

        await consultarBanco(sql, [
            req.usuario.usuario_id,
            stateHash,
            verifierCriptografado
        ]);

        const parametros = new URLSearchParams({
            client_id: clientId,
            response_type: 'code',
            platform_id: 'mp',
            state,
            redirect_uri: redirectUri,
            code_challenge: codeChallenge,
            code_challenge_method: 'S256'
        });

        return res.status(200).json({
            authorizationUrl:
                `${MP_AUTH_URL}?${parametros.toString()}`
        });

    } catch (erro) {
        console.error(
            'Erro ao iniciar OAuth:',
            erro.message
        );

        return res.status(500).json({
            erro: 'Não foi possível iniciar a conexão com o Mercado Pago.'
        });
    }
};

// Recebe o retorno do Mercado Pago
const callbackMercadoPago = async (req, res) => {
    const { code, state, error } = req.query;

    if (error) {
        return res.redirect(
            `${FRONTEND_URL}/?mercadopago=cancelado`
        );
    }

    if (!code || !state || Array.isArray(code) || Array.isArray(state)) {
        return res.status(400).send(
            'Retorno inválido do Mercado Pago.'
        );
    }

    if (
        !process.env.MP_CLIENT_ID ||
        !process.env.MP_CLIENT_SECRET ||
        !process.env.MP_REDIRECT_URI ||
        !process.env.MP_TOKEN_ENCRYPTION_KEY
    ) {
        return res.status(500).send(
            'Configurações do Mercado Pago não encontradas.'
        );
    }

    try {
        const stateHash = crypto
            .createHash('sha256')
            .update(state)
            .digest('hex');

        const sqlBusca = `
            SELECT
                oauth_id,
                usuario_id,
                code_verifier_enc
            FROM mercadopago_oauth
            WHERE state_hash = ?
              AND expira_em > NOW()
              AND consumido_em IS NULL
            LIMIT 1
        `;

        const resultados = await consultarBanco(
            sqlBusca,
            [stateHash]
        );

        if (resultados.length === 0) {
            return res.status(400).send(
                'Autorização inválida ou expirada. Tente novamente.'
            );
        }

        const tentativa = resultados[0];

        const sqlConsumir = `
            UPDATE mercadopago_oauth
            SET consumido_em = NOW()
            WHERE oauth_id = ?
              AND consumido_em IS NULL
              AND expira_em > NOW()
        `;

        const resultadoConsumo = await consultarBanco(
            sqlConsumir,
            [tentativa.oauth_id]
        );

        if (resultadoConsumo.affectedRows !== 1) {
            return res.status(400).send(
                'Esta autorização já foi utilizada ou expirou.'
            );
        }

        const codeVerifier = descriptografarToken(
            tentativa.code_verifier_enc
        );

        const resposta = await fetch(MP_TOKEN_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                client_id: process.env.MP_CLIENT_ID,
                client_secret: process.env.MP_CLIENT_SECRET,
                grant_type: 'authorization_code',
                code,
                redirect_uri: process.env.MP_REDIRECT_URI,
                code_verifier: codeVerifier
            }),
            signal: AbortSignal.timeout(15000)
        });

        let dados;

        try {
            dados = await resposta.json();
        } catch {
            console.error(
                'O Mercado Pago retornou uma resposta inválida.'
            );

            return res.status(502).send(
                'Resposta inválida do Mercado Pago.'
            );
        }

        if (!resposta.ok) {
            console.error(
                'Erro na troca de token:',
                resposta.status,
                dados.error
            );

            return res.status(502).send(
                'Não foi possível concluir a conexão com o Mercado Pago.'
            );
        }

        if (
            !dados.access_token ||
            !dados.refresh_token ||
            !dados.user_id ||
            !Number.isFinite(Number(dados.expires_in)) ||
            Number(dados.expires_in) <= 0
        ) {
            return res.status(502).send(
                'O Mercado Pago retornou dados incompletos.'
            );
        }

        const accessTokenEnc = criptografarToken(
            dados.access_token
        );

        const refreshTokenEnc = criptografarToken(
            dados.refresh_token
        );

        const sqlSalvar = `
            INSERT INTO mercadopago_conexao (
                usuario_id,
                mp_user_id,
                access_token_enc,
                refresh_token_enc,
                public_key,
                token_expira_em
            )
            VALUES (
                ?, ?, ?, ?, ?,
                DATE_ADD(NOW(), INTERVAL ? SECOND)
            )
            ON DUPLICATE KEY UPDATE
                mp_user_id = VALUES(mp_user_id),
                access_token_enc = VALUES(access_token_enc),
                refresh_token_enc = VALUES(refresh_token_enc),
                public_key = VALUES(public_key),
                token_expira_em = VALUES(token_expira_em),
                atualizado_em = CURRENT_TIMESTAMP
        `;

        await consultarBanco(sqlSalvar, [
            tentativa.usuario_id,
            String(dados.user_id),
            accessTokenEnc,
            refreshTokenEnc,
            dados.public_key || null,
            Number(dados.expires_in)
        ]);

        return res.redirect(
            `${FRONTEND_URL}/?mercadopago=conectado`
        );

    } catch (erro) {
        console.error(
            'Erro ao concluir OAuth do Mercado Pago:',
            erro.message
        );

        return res.status(500).send(
            'Ocorreu um erro ao conectar a conta do Mercado Pago.'
        );
    }
};

module.exports = {
    conectarMercadoPago,
    callbackMercadoPago
};
