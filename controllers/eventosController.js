const conexao = require('../config/db');

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

    const sql = `INSERT INTO evento (
            codigo_evento,
            tipo_evento,
            quantidade_convidados,
            descricao,
            data_evento,
            local_evento,
            cidade_evento,
            estado_evento,
            usuario_id
        ) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
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
            usuario_id

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
            evento_id: resultado.insertId

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


module.exports = {
    cadastrarEvento,
    listarEvento,
    buscarEventoUsuario,
    acessarEvento
};