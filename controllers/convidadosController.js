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
    
    const responderConvite = (req, res) => {

        const { token } = req.params;
        const { status_confirmacao } = req.body;

    

    if (!status_confirmacao) {
        return res.status(400).json({
            erro: 'Status de confirmação não informado'
        });
    }

    if (
        status_confirmacao !== 'CONFIRMADO' && status_confirmacao !== 'RECUSADO'
    ) {
        return res.status(400).json({
            erro: 'Status inválido'
        });
    }

    const sql = `

        UPDATE convidado
        SET status_confirmacao = ?
        WHERE token_convite = ?
    `;

    conexao.query(
        sql, [status_confirmacao, token],
        (erro,resultado) => {

            if (erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao atualizar confirmação'
                });
            }

            if (resultado.affectedRows === 0) {
                return res.status(404).json({
                    erro: 'Convite não encontrado'
                });
            }

            return res.status(200).json({
                mensagem: 'Resposta do convite registrada',
                status_confirmacao: status_confirmacao
            });
        }
    );
};

const cadastrarConvidadoPublico = (req, res) => {
    const { token } = req.params;

    const {
        nome,
        email,
        telefone,
        criancas_0_3 = 0,
        criancas_4_7 = 0,
        acompanhantes_8_mais = 0,
        status_confirmacao
    } = req.body;

    if (!nome || !email || !telefone) {
        return res.status(400).json({
            erro: 'Informe nome, email e telefone.'
        });
    }

    if ( 
        !['CONFIRMADO', 'RECUSADO'].includes(status_confirmacao)
    ) {
        return res.status(400).json({
            erro: 'Resposta do convite inválida.'
        });
    }

    const faixas = [
        criancas_0_3,
        criancas_4_7,
        acompanhantes_8_mais
    ];

    const quantidadeValidas = faixas.every(
        quantidade =>
            Number.isInteger(Number(quantidade)) && Number(quantidade) >= 0
    );

    if (!quantidadeValidas) {
        return res.status(400).json({
            erro: 'As quantidades devem ser númerps inteiros não negativos.'
        });
    }

    const totalAcompanhantes = faixas.reduce(
        (total, quantidade) => total + Number(quantidade), 0
        
    );

    const sqlEvento = `
        SELECT evento_id, usuario_id
        FROM evento
        WHERE token_convite = ?
    `;

    
conexao.query(sqlEvento, [token], (erro, eventos) => {
    if (erro) {
        console.log(erro);
        return res.status(500).json({
            erro: 'Erro ao localizar o evento.'
        });
    }

    if (eventos.length === 0) {
        return res.status(404).json({
            erro: 'Convite inválido ou evento não encontrado.'
        });
    }

    const evento = eventos[0];

        const sqlConvidado = `
            INSERT INTO convidado (
                nome,
                email,
                telefone,
                evento_id,
                usuario_id,
                status_confirmacao,
                quantidade_acompanhantes,
                criancas_0_3,
                criancas_4_7,
                acompanhantes_8_mais
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        conexao.query(
            sqlConvidado,
            [
                nome.trim(),
                email.trim(),
                telefone.trim(),
                evento.evento_id,
                evento.usuario_id,
                status_confirmacao,
                totalAcompanhantes,
                Number(criancas_0_3),
                Number(criancas_4_7),
                Number(acompanhantes_8_mais)
            ],
            (erroInsert, resultado) => {
                if (erroInsert) {
                    console.log(erroInsert);
                    return res.status(500).json({
                        erro: 'Erro ao registrar sua resposta.'
                    });
                }

                return res.status(201).json({
                    mensagem: 'Resposta registrada com sucesso!',
                    convidado_id: resultado.insertId,
                    status_confirmacao,
                    quantidade_acompanhantes: totalAcompanhantes
                });
            }
        );
    });
};

module.exports = {
    cadastrarConvidado,
    cadastrarConvidadoPublico,
    buscarConvitePorToken,
    responderConvite,
    listarConvidadosPorEvento,
    alterarStatusConvidados,
    excluirConvidado
};