const conexao = require('../config/db');
const crypto = require('crypto');

const authConvidadoMiddleware = (req, res, next) => {
    const authorization = req.headers.authorization;

    if (!authorization || !authorization.startsWith('Bearer ')) {
        return res.status(401).json({
            erro: 'Token de acesso não informado.'
        });
    }

    const accessToken = authorization.substring(7);

    const accessTokenHash = crypto
        .createHash('sha256')
        .update(accessToken)
        .digest('hex');

    const sql = `
        SELECT
            s.sessao_id,
            s.convidado_id,
            s.evento_id,
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
        WHERE s.access_token_hash = ?
          AND s.access_expira_em > NOW()
          AND s.revogado_em IS NULL
        LIMIT 1
    `;

    conexao.query(sql, [accessTokenHash], (erro, sessoes) => {
        if (erro) {
            console.error('Erro ao autenticar convidado:', erro);

            return res.status(500).json({
                erro: 'Erro ao verificar autenticação.'
            });
        }

        if (sessoes.length === 0) {
            return res.status(401).json({
                erro: 'Sessão inválida ou expirada.'
            });
        }

        const sessao = sessoes[0];

        if (sessao.evento_encerrado === 1) {
            return res.status(403).json({
                erro: 'O prazo de acesso a este evento foi encerrado.'
            });
        }

        req.convidado = {
            sessao_id: sessao.sessao_id,
            convidado_id: sessao.convidado_id,
            evento_id: sessao.evento_id
        };

        next();
    });
};

module.exports = authConvidadoMiddleware;