const conexao = require('../config/db');

const cadastrarPresente = (req, res) => {
    const {
        nome_presente,
        descricao,
        valor,
        link_loja,
        status_produto,
        evento_id
    } = req.body;

    const sql = `
        INSERT INTO presente 
        (
            nome_presente,
            descricao,
            valor,
            link_loja,
            status_produto,
            evento_id
        )
            VALUES (?, ?, ?, ?, ?, ?)
    `;

    conexao.query(
        sql,
        [
            nome_presente,
            descricao,
            valor,
            link_loja,
            status_produto,
            evento_id
        ],
        (erro, resultado) => {
            if (erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao cadastrar presente'
                });
            }

            return res.status(201).json({
                mensagem: 'Presente cadastrado com sucesso',
                presente_id: resultado.insertId
            });
        }
    );
};

const listarPresentes = (req, res) => {
    const sql =`
    SELECT * FROM presente
    ORDER BY nome_presente
    `;

    conexao.query(
        sql,
        (erro, resultado) => {
            if(erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao listar presentes'
                });
            }

            return res.status(200).json(resultado);
        }
    );
};

const listarPresentesEvento = (req, res) => {

    const { eventoId } = req.params;

    const sql = `
        SELECT *
        FROM presente
        WHERE evento_id = ?
        ORDER BY nome_presente
    `;

    conexao.query(
        sql,
        [eventoId],
        (erro, resultado) => {

            if (erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao listar presentes'
                });
            }

            return res.status(200).json(resultado);
        }
    );
};

module.exports = {
    cadastrarPresente,
    listarPresentes,
    listarPresentesEvento
};