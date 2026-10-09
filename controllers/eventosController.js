const conexao = require('../config/db');
const crypto = require('crypto');

const cadastrarEvento = (req, res) => {

    const {
        tipo_evento,
        quantidade_convidados,
        descricao,
        data_evento,
        local_evento,
        cidade_evento,
        estado_evento,
        usuario_id
        
    } = req.body;

    const codigo_evento = `EVE${Math.floor(1000 + Math.random() * 9000)}`;
    const tokenConvite = crypto.randomBytes(32).toString('hex');

    const sql = `INSERT INTO evento (
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

    conexao.query(
        sql,
        [
            codigo_evento,
            tipo_evento,
            quantidade_convidados,
            descricao,
            data_evento,
            local_evento,
            cidade_evento,
            estado_evento,
            usuario_id,
            tokenConvite

        ],
        (erro, resultado) => {
            if(erro){
                console.log(erro);

            return res.status(500).json({
                erro: 'Erro nessa bagaça para cadastrar'
            });
        }

        return res.status(201).json({
            mensagem: 'Evento criado na boa!',
            codigo_evento: codigo_evento,
            evento_id: resultado.insertId,
            token_convite: tokenConvite

            });
        }
    
    );
};

const listarEvento = (req, res) => {

    const sql = 'SELECT * FROM evento';

    conexao.query(sql, (erro, resultado) => {

        if (erro) {
            console.log(erro);

            return res.status(500).json({
                erro: 'Erro ao listar evento'
            });
        }

        return res.status(200).json(resultado);
    });
};

const buscarEventoUsuario = (req, res) => {

    const { usuarioId } = req.params;

    const sql = `
        SELECT * FROM evento
        WHERE usuario_id = ?
    `;

    conexao.query(
        sql,
        [usuarioId], (erro, resultado) =>  {
            if(erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao buscar evento '
                });
            }

            if (resultado.length  === 0) {
                return res.status(404).json({
                    erro: 'Evento não encontrado'
                });
            }

            return res.status(200).json(resultado[0]);
        }
    );
};

const acessarEvento = (req, res) => {
    const {codigo_evento} = req.body;

    if (!codigo_evento) {
        return res.status(400).json({
            erro: 'Código do evento não informado'
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
            estado_evento
        FROM evento WHERE codigo_evento = ?
    `;

    conexao.query(
        sql,
        [codigo_evento],
        (erro, resultado) => {

            if (erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao buscar evento!!'
                });
            }

            if (resultado.length === 0) {
                return res.status(404).json({
                    erro: 'Código do evento inválido!!'
                });
            }

            return res.status(200).json({
                mensagem: 'Evento encontrato',
                evento: resultado[0]
            });
        }
    );
};

const buscarEventoPorToken = (req, res) => {
    const { token } = req.params;

    if (!token) {
        return res.status(400).json({
            erro: 'Token do convite não informado'
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
            estado_evento
        FROM evento
        WHERE token_convite = ?
    `;

    conexao.query(
        sql,[token],
        (erro, resultado) => {

            if (erro) {
                console.log(erro)

                return res.status(500).json({
                    erro: 'Erro ao buscar evento pelo convite'
                });
            }

            if (resultado.length === 0) {
                return res.status(400).json({
                    erro: 'Convite inválido ou evento não encontrado! '
                });
            }

            return res.status(200).json({
                mensagem: 'Evento encontrado',
                evento: resultado[0]
            });
        }
    );
};

const importarConvite = (req, res) => {

    const { eventoId } = req.params;

    if (!req.file) {
        return res.status(400).json({
            erro: 'Nenhum convite foi enviado'
        });
    }

    const urlConvite = `/uploads/convites/${req.file.filename}`;

    const sql = `
        UPDATE evento
        SET convite_url = ?
        WHERE evento_id = ?
    `;

    conexao.query(
        sql,
        [urlConvite, eventoId],
        (erro, resultado) => {

            if (erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao salvar convite'
                });
            }

            if (resultado.affectedRows === 0) {
                return res.status(404).json({
                    erro: 'Evento não encontrado'
                });
            }

            return res.status(200).json({
                mensagem: 'Convite importado com sucesso',
                convite_url: urlConvite
            });
        }
    );
};


module.exports = {
    cadastrarEvento,
    listarEvento,
    buscarEventoUsuario,
    acessarEvento,
    buscarEventoPorToken,
    importarConvite
};