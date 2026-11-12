const conexao = require("../config/db");

const verificarEventoAdministrador = (usuarioId, eventoId, callback) => {
  const sql = `
        SELECT evento_id
        FROM evento
        WHERE evento_id = ?
          AND usuario_id = ?
        LIMIT 1
    `;

  conexao.query(sql, [eventoId, usuarioId], (erro, resultados) => {
    if (erro) {
      return callback(erro);
    }

    callback(null, resultados.length > 0 ? resultados[0].evento_id : null);
  });
};

const buscarOrcamento = (req, res) => {
  const { eventoId } = req.params;
  const usuarioId = req.usuario.usuario_id;

  verificarEventoAdministrador(usuarioId, eventoId, (erro, eventoValidado) => {
    if (erro) {
      console.error(erro);

      return res.status(500).json({
        erro: "Erro ao validar evento.",
      });
    }

    if (!eventoValidado) {
      return res.status(403).json({
        erro: "Evento não encontrado ou não pertence ao administrador.",
      });
    }

    const sql = `
                SELECT
                    evento.orcamento_total,
                    IFNULL(SUM(fornecedor.valor), 0) AS gasto
                FROM evento
                LEFT JOIN fornecedor
                    ON evento.evento_id = fornecedor.evento_id
                WHERE evento.evento_id = ?
                GROUP BY evento.evento_id, evento.orcamento_total
            `;

    conexao.query(sql, [eventoValidado], (erro, resultado) => {
      if (erro) {
        console.error(erro);

        return res.status(500).json({
          erro: "Erro ao buscar orçamento.",
        });
      }

      if (resultado.length === 0) {
        return res.status(404).json({
          erro: "Evento não encontrado.",
        });
      }

      const orcamento = Number(resultado[0].orcamento_total);

      const gasto = Number(resultado[0].gasto);

      const saldo = orcamento - gasto;

      return res.status(200).json({
        orcamento_total: orcamento,
        gasto,
        saldo,
      });
    });
  });
};

const atualizarOrcamento = (req, res) => {
    const { eventoId } = req.params;
    const { orcamento_total } = req.body;
    const usuarioId = req.usuario.usuario_id;

    if (
        orcamento_total === undefined ||
        !Number.isFinite(Number(orcamento_total)) ||
        Number(orcamento_total) < 0
    ) {
        return res.status(400).json({
            erro: 'Informe um valor de orçamento válido.'
        });
    }

    verificarEventoAdministrador(
        usuarioId,
        eventoId,
        (erro, eventoValidado) => {
            if (erro) {
                console.error(erro);

                return res.status(500).json({
                    erro: 'Erro ao validar evento.'
                });
            }

            if (!eventoValidado) {
                return res.status(403).json({
                    erro: 'Evento não encontrado ou não pertence ao administrador.'
                });
            }

            const sql = `
                UPDATE evento
                SET orcamento_total = ?
                WHERE evento_id = ?
            `;

            conexao.query(
                sql,
                [Number(orcamento_total), eventoValidado],
                (erro) => {
                    if (erro) {
                        console.error(erro);

                        return res.status(500).json({
                            erro: 'Erro ao atualizar orçamento.'
                        });
                    }

                    return res.status(200).json({
                        mensagem: 'Orçamento atualizado com sucesso.'
                    });
                }
            );
        }
    );
};

module.exports = {
  buscarOrcamento,
  atualizarOrcamento,
};
