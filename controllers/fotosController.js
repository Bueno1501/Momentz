const conexao = require('../config/db');

const uploadFoto = (req, res) => {

    if (!req.file) {
        return res.status(400).json({
            erro: 'Nenhuma foto enviada'
        });
    }

    const  evento_id  = parseInt (req.body.evento_id);

    const nomeArquivo = req.file.filename;

    const urlFoto = `/uploads/${nomeArquivo}`;

    const sql = `
        INSERT INTO foto(
            url_foto,
            nome_arquivo,
            evento_id
        )
            VALUES(?, ?, ?)
    `;

    conexao.query(
        sql,
        [
            urlFoto,
            nomeArquivo,
            evento_id
        ],

        (erro, resultado) => {
            if(erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao Salvar foto'
                });
            }

            return res.status(201).json({
                mensagem: 'Foto enviado com sucesso',
                foto_id: resultado.insertId,
                url_foto: urlFoto
            });
        }
    );

}

  const listarFotosPorEvento = (req, res) => {

        const { eventoId } = req.params;

        const sql = `
            SELECT * FROM foto
            WHERE evento_id = ? 
            ORDER BY foto_id DESC
        `;

        conexao.query(
            sql, [eventoId],

            (erro, resultado) => {
                if (erro) {
                    console.log(erro);

                    return res.status(500).json({
                        erro: 'Erro ao buscar fotos'
                    });
                }

                return res.status(200).json(resultado);
            }
        );
    };

 module.exports = {
    uploadFoto,
    listarFotosPorEvento
  };