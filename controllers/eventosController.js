
const conexao = require('../config/db');
const crypto = require('crypto');
const path = require('path');

const {
    enviarArquivo,
    gerarUrlTemporaria
} = require('../services/r2Service');

// ============================================================
// CADASTRAR EVENTO
// ============================================================

const cadastrarEvento = (req, res) => {

    const {
        tipo_evento,
        quantidade_convidados,
        descricao,
        data_evento,
        local_evento,
        cidade_evento,
        estado_evento
    } = req.body;

    // O ID vem do JWT, não do corpo da requisição.
    const usuarioId = req.usuario.usuario_id;

    const tokenConvite = crypto.randomBytes(32).toString('hex');

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
    const codigoEvento = `EVE${crypto.randomBytes(4).toString('hex').slice(0, 7).toUpperCase()}`;

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
            tokenConvite
        ],
        (erro, resultado) => {

            if (erro) {
                console.error('Erro ao cadastrar evento:', erro);

                if (erro.code === 'ER_DUP_ENTRY') {
                    return res.status(409).json({
                        erro: 'Não foi possível gerar um código único. Tente novamente.'
                    });
                }

                return res.status(500).json({
                    erro: 'Erro ao cadastrar evento.'
                });
            }

            return res.status(201).json({
                mensagem: 'Evento cadastrado com sucesso!',
                codigo_evento: codigoEvento,
                evento_id: resultado.insertId,
                token_convite: tokenConvite
            });
        }
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

    conexao.query(
        sql,
        [usuarioId],
        (erro, resultado) => {

            if (erro) {
                console.error('Erro ao buscar eventos do administrador:', erro);

                return res.status(500).json({
                    erro: 'Erro ao buscar eventos.'
                });
            }

            // Retorna uma lista, mesmo quando não existem eventos.
            return res.status(200).json(resultado);
        }
    );
};


// ============================================================
// ACESSAR EVENTO PELO CÓDIGO
// ============================================================

const acessarEvento = (req, res) => {

    const { codigo_evento } = req.body;

    if (!codigo_evento) {
        return res.status(400).json({
            erro: 'Código do evento não informado.'
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

    conexao.query(
        sql,
        [codigo_evento],
        (erro, resultado) => {

            if (erro) {
                console.error('Erro SQL ao buscar evento:', erro);

                return res.status(500).json({
                    erro: 'Erro ao buscar evento.'
                });
            }

            if (resultado.length === 0) {
                return res.status(404).json({
                    erro: 'Código do evento inválido.'
                });
            }

            return res.status(200).json({
                mensagem: 'Evento encontrado.',
                evento: resultado[0]
            });
        }
    );
};


// ============================================================
// BUSCAR EVENTO PELO TOKEN DO CONVITE
// ============================================================

const buscarEventoPorToken = (req, res) => {

    const { token } = req.params;

    if (!token) {
        return res.status(400).json({
            erro: 'Token do convite não informado.'
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
            convite_url
        FROM evento
        WHERE token_convite = ?
    `;

    conexao.query(
        sql,
        [token],
        async (erro, resultado) => {

            if (erro) {
                console.error('Erro ao buscar evento pelo convite:', erro);

                return res.status(500).json({
                    erro: 'Erro ao buscar evento pelo convite.'
                });
            }

            if (resultado.length === 0) {
                return res.status(404).json({
                    erro: 'Convite inválido ou evento não encontrado.'
                });
            }

            const evento = resultado[0];

            if (evento.convite_url) {
                try {

                    if (evento.convite_url.startsWith('convites/')) {
                        evento.convite_url = await gerarUrlTemporaria(
                            evento.convite_url
                        );
                    } else if (!evento.convite_url.startsWith('http')) {
                        evento.convite_url = null;
                    }

                } catch (erroUrl) {
                    console.error('Erro ao gerar URL do convite:', erroUrl);

                    return res.status(502).json({
                        erro: 'Não foi possível carregar a imagem do convite.'
                    });
                }
            }

            return res.status(200).json({
                mensagem: 'Evento encontrado.',
                evento
            });
        }
    );
};


// ============================================================
// IMPORTAR CONVITE PARA O R2
// ============================================================

const importarConvite = async (req, res) => {

    const { eventoId } = req.params;
    const usuarioId = req.usuario.usuario_id;

    if (!req.file) {
        return res.status(400).json({
            erro: 'Nenhum convite foi enviado.'
        });
    }

    // Primeiro verifica se o evento pertence ao administrador.
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
                console.error('Erro ao verificar propriedade do evento:', erro);

                return res.status(500).json({
                    erro: 'Erro ao verificar evento.'
                });
            }

            if (resultado.length === 0) {
                return res.status(404).json({
                    erro: 'Evento não encontrado ou não pertence a este administrador.'
                });
            }

            const extensao = path.extname(req.file.originalname);
            const nomeArquivo = `${crypto.randomUUID()}${extensao}`;
            const chave = `convites/${eventoId}/${nomeArquivo}`;

            try {

                await enviarArquivo({
                    chave,
                    buffer: req.file.buffer,
                    tipoConteudo: req.file.mimetype
                });

            } catch (erroUpload) {
                console.error('Erro ao enviar convite para o R2:', erroUpload);

                return res.status(502).json({
                    erro: 'Não foi possível armazenar o convite.'
                });
            }

            // Atualiza somente se o evento continuar pertencendo ao administrador.
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
                        console.error('Erro ao salvar convite no banco:', erroUpdate);

                        return res.status(500).json({
                            erro: 'Erro ao salvar convite.'
                        });
                    }

                    if (resultadoUpdate.affectedRows === 0) {
                        return res.status(404).json({
                            erro: 'Evento não encontrado.'
                        });
                    }

                    try {

                        const url = await gerarUrlTemporaria(chave);

                        return res.status(200).json({
                            mensagem: 'Convite importado com sucesso!',
                            convite_url: url
                        });

                    } catch (erroUrl) {
                        console.error('Erro ao gerar URL do convite:', erroUrl);

                        return res.status(200).json({
                            mensagem: 'Convite armazenado, mas não foi possível gerar o link.',
                            convite_url: null
                        });
                    }
                }
            );
        }
    );
};


// ============================================================
// BUSCAR EVENTO POR ID
// ============================================================

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

    conexao.query(
        sql,
        [eventoId, usuarioId],
        (erro, resultado) => {

            if (erro) {
                console.error('Erro ao buscar evento:', erro);

                return res.status(500).json({
                    erro: 'Erro ao buscar evento.'
                });
            }

            if (resultado.length === 0) {
                return res.status(404).json({
                    erro: 'Evento não encontrado.'
                });
            }

            return res.status(200).json(resultado[0]);
        }
    );
};


module.exports = {
    cadastrarEvento,
    buscarEventoUsuario,
    acessarEvento,
    buscarEventoPorToken,
    importarConvite,
    buscarEventoPorId
};
