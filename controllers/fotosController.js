
const conexao = require('../config/db');
const crypto = require('crypto');
const { enviarArquivo, gerarUrlTemporaria } = require('../services/r2Service');

const uploadFoto = async (req, res) => {
    if (!req.file) {
        return res.status(400).json({
            erro: 'Nenhuma foto enviada'
        });
    }

    const evento_id = Number.parseInt(req.body.evento_id, 10);

    if (!Number.isInteger(evento_id) || evento_id <= 0) {
        return res.status(400).json({
            erro: 'Evento inválido'
        });
    }

    const extensao = require('path').extname(req.file.originalname);
    const nomeArquivo = `${crypto.randomUUID()}${extensao}`;
    const chave = `fotos/${evento_id}/${nomeArquivo}`;

    try {
        await enviarArquivo({
            chave,
            buffer: req.file.buffer,
            tipoConteudo: req.file.mimetype
        });
    } catch (erro) {
        console.error('Erro ao enviar foto para o R2:', erro);
        return res.status(502).json({
            erro: 'Não foi possível armazenar a foto'
        });
    }

    const sql = `
        INSERT INTO foto (url_foto, nome_arquivo, evento_id)
        VALUES (?, ?, ?)
    `;

    conexao.query(sql, [chave, nomeArquivo, evento_id], async (erro, resultado) => {
        if (erro) {
            console.error('Erro ao salvar foto no banco:', erro);
            return res.status(500).json({
                erro: 'A foto foi enviada, mas não foi possível registrar no banco'
            });
        }

        try {
            const url = await gerarUrlTemporaria(chave);

            return res.status(201).json({
                mensagem: 'Foto enviada com sucesso',
                foto_id: resultado.insertId,
                url_foto: url
            });
        } catch (erroUrl) {
            console.error('Erro ao gerar URL da foto:', erroUrl);
            return res.status(201).json({
                mensagem: 'Foto enviada com sucesso',
                foto_id: resultado.insertId,
                url_foto: null
            });
        }
    });
};

const listarFotosPorEvento = (req, res) => {
    const { eventoId } = req.params;

    const sql = `
        SELECT * FROM foto
        WHERE evento_id = ?
        ORDER BY foto_id DESC
    `;

    conexao.query(sql, [eventoId], async (erro, resultado) => {
        if (erro) {
            console.error('Erro ao buscar fotos:', erro);
            return res.status(500).json({
                erro: 'Erro ao buscar fotos'
            });
        }

        try {
            const fotos = await Promise.all(
                resultado.map(async (foto) => ({
                    ...foto,
                    url_foto: await gerarUrlTemporaria(foto.url_foto)
                }))
            );

            return res.status(200).json(fotos);
        } catch (erroUrl) {
            console.error('Erro ao gerar URLs das fotos:', erroUrl);
            return res.status(500).json({
                erro: 'Erro ao preparar visualização das fotos'
            });
        }
    });
};

module.exports = {
    uploadFoto,
    listarFotosPorEvento
};
