const conexao = require('../config/db');

const cadastrarFornecedor = (req, res) => {
    const{
        nome,
        categoria,
        telefone,
        email,
        valor,
        observacao,status_fornecedor,
        evento_id
    } = req.body;

    const sql = `
        INSERT INTO fornecedor
        (
            nome,
            categoria,
            telefone,
            email,
            valor,
            observacao,
            status_fornecedor,
            evento_id
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    conexao.query(
        sql,
        [
            nome,
            categoria,
            telefone,
            email,
            valor,
            observacao,
            status_fornecedor,
            evento_id
        ],
        (erro, resultado) => {

            if (erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao cadastrar fornecedor'
                });
            }

            return res.status(201).json({
                mensagem: 'Fornecedor cadastrado com sucesso!',
                fornecedor_id: resultado.insertId
            });
        }
    );
};

const listarFornecedores = (req, res) => {
    const sql = `
    SELECT * FROM fornecedor
    ORDER BY nome
    `;

    conexao.query(
        sql,
        (erro, resultado) => {
            if(erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao listar fornecedores'
                });
            }

            return res.status(200).json(resultado);
        }
    );
};

const listarFornecedoresEvento = (req, res) => {

    const { eventoId } = req.params;

    const sql = `
        SELECT *
        FROM fornecedor
        WHERE evento_id = ?
        ORDER BY nome
    `;

    conexao.query(
        sql,
        [eventoId],
        (erro, resultado) => {

            if (erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao listar fornecedores'
                });
            }

            return res.status(200).json(resultado);
        }
    );
};

module.exports = {
    cadastrarFornecedor,
    listarFornecedores,
    listarFornecedoresEvento
};