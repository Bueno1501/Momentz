const conexao = require('../config/db');

const crypto =  require('crypto');

const cadastrarConvidado = (req, res) => {
    const{
        nome,
        email,
        telefone,
        evento_id,
        usuario_id
    } = req.body;

    const tokenConvite = crypto.randomBytes(32).toString('hex');

    const sql = `
        INSERT INTO Convidado
    (
         nome,
         email, 
         telefone,
         evento_id, 
         usuario_id, 
         status_confirmacao,
         token_convite
    )
        VALUES (?, ?, ?, ?, ?, 'PENDENTE', ?)
    `;

    conexao.query(
        sql,
        [nome, email, telefone, evento_id, usuario_id || null, tokenConvite],
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

const buscarConvitePorToken = (req, res) => {
    const { token } = req.params;

    const sql = `
        SELECT
            convidado.convidado_id,
            convidado.nome,
            convidado.email,
            convidado.telefone,
            convidado.status_confirmacao,
            evento.evento_id,
            evento.codigo_evento,
            evento.tipo_evento,
            evento.data_evento,
            evento.local_evento,
            evento.cidade_evento,
            evento.estado_evento,
            evento.descricao
        FROM convidado INNER JOIN evento ON convidado.evento_id = evento.evento_id
        WHERE convidado.token_convite = ?
    `;

    conexao.query(
        sql, [token], (erro, resultado) => {

        if (erro){
            console.log(erro);

            return res.status(500).json({
                erro: 'Erro ao buscar convite'
            });
        }

        if (resultado.length === 0) {
            return res.status(404).json({
                erro: 'Convite não encontrado ou inválido'
            });
        }

        return res.status(200).json({
            mensagem: 'Convite encontrado',
            convite: resultado[0]
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
    buscarConvitePorToken,
    listarConvidadosPorEvento,
    alterarStatusConvidados,
    excluirConvidado
};