const conexao = require('../config/db');

const cadastrarConvidado = (req, res) => {
    const{
        nome,
        email,
        evento_id,
        usuario_id
    } = req.body;

    const sql = `
        INSERT INTO Convidado
        (nome, email, evento_id, usuario_id, status_confirmacao)
        VALUES (?, ?, ?, ?, 'PENDENTE')
    `;

    conexao.query(
        sql,
        [nome, email,evento_id, usuario_id || null],
        (erro, resultado) => {
            if (erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao Cadastrar convidado'
                });
            }

            res.status(201).json({
                mensagem:'Convidado cadastrado com sucesso',
                convidado_id: resultado.insertId
            });
        }
    );
};

 const listarConvidadosPorEvento = (req, res) => {

    const {eventoId} = req.params;

        const sql = `
        SELECT * FROM
        convidado WHERE evento_id = ?
         ORDER BY nome
        `;

        conexao.query(sql, [eventoId], (erro, resultado) => {
            if (erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao Buscar convidados'
                });
            }
            res.status(200).json(resultado);
        });
    };

    const alterarStatusConvidados =  (req, res) =>
    {
        const {convidadoId} = req.params;
        const {status_confirmacao} = req.body;

        const sql =`
            UPDATE convidado SET
            status_confirmacao = ?
            WHERE convidado_id =?
        `;

        conexao.query(
            sql,
            [status_confirmacao, convidadoId],
            (erro, resultado) => {

                if (erro) {
                    console.log(erro);

                    return res.status(500).json({
                        erro: 'Erro ao atualizar status'
                    });
                }

                return res.status(200).json({
                    mensagem: 'Status atualizado com sucesso '
                });
            }
        );
    };

    const excluirConvidado = (req, res) => {

        const {convidadoId} = req.params;

        const sql = `
            DELETE FROM convidado 
            WHERE convidado_id = ?
        `;

        conexao.query(
            sql,
            [convidadoId],
            (erro, resultado) => {
                if (erro) {
                    console.log(erro);

                    return res.status(500).json({
                        erro: 'Erro ao excluir convidado'
                    });
                }

                return res.status(200).json({
                    mensagem: 'Convidado excluido com sucesso'
                });
            }
        );
    };


module.exports = {
    cadastrarConvidado,
    listarConvidadosPorEvento,
    alterarStatusConvidados,
    excluirConvidado
};