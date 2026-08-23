const conexao = require('../config/db');

const buscarOrcamento = (req, res) => {
    const { eventoId } = req.params;

    const sql = `SELECT evento.orcamento_total,
    IFNULL(SUM(fornecedor.valor), 0) AS gasto FROM evento
    
    LEFT JOIN fornecedor ON evento.evento_id = fornecedor.evento_id
    
    WHERE evento.evento_id = ? 
    
    GROUP BY evento.orcamento_total `;

    conexao.query(sql, [eventoId], (erro, resultado) => {

        if (erro) {
            console.log(erro);

            return res.status(500).json ({
                erro: 'Erro ao buscar orçamemto'
            });
        }

        if (resultado.length == 0) {
            return res.status(404).json({
                erro: 'Evento não encontrado'
            });
        }

        const orcamento = Number(resultado[0].orcamento_total);
        const gasto = Number(resultado[0].gasto);
        const saldo = orcamento - gasto;

        return res.status(200).json({
            orcamento_total: orcamento, gasto, saldo
        });
    });

};

const atualizarOrcamento = (req, res) => {
    const { eventoId } = req.params;
    const { orcamento_total } = req.body;

    const sql = `
        UPDATE evento
        SET orcamento_total = ?
        WHERE evento_id = ?
        `;

    conexao.query(

        sql,
        [
            orcamento_total,
            eventoId,
        ],

        (erro) => {
        if (erro){
            console.log(erro);

            return res.status(500).json({
                erro: 'Erro ao atualizar orçamento'
            });
        }

        return res.status(200).json({
            mensagem: 'Orçamento atualizado com sucesso'
        });
      }
   );
};

module.exports = {
    buscarOrcamento,
    atualizarOrcamento
};