const conexao = require('../config/db');

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const { enviarEmailBoasVindas } = require('../services/emailServices');

const cadastrarUsuario = async (req, res) => {

    const{nome, email, senha, tipo_usuario} = req.body;

    const senhaHash = await bcrypt.hash(senha, 10);

    console.log('HASH GERADO:', senhaHash);


    const sql = `INSERT INTO usuario (nome, email, senha, tipo_usuario)
                VALUES(?, ?, ?, ?)
    `;

    conexao.query(
        sql,
        [nome, email, senhaHash,tipo_usuario],
        async (erro, resultado) => {

            if(erro ) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Deu erro no cadastro do user man!'
                });
            }
            try {
                await enviarEmailBoasVindas(email, nome);
            } catch (erroEmail) {

                console.log('Erro ao enviar e-mail:');
                console.log(erroEmail);
            }

            res.status(201).json({
                mensagem: 'Usuário cadastrado com sucesso!!',
                usuarioId: resultado.insertId
            });
        }
    );
};

const login = async (req, res) => {
    const{ email, senha} = req.body;

    const sql = `
    SELECT * 
    FROM usuario
    WHERE email = ?
    `;

    conexao.query(
        sql, [email], async (erro, resultado) => {

            if(erro) {
                console.log(erro);

                return res.status(500).json({
                    erro: 'Erro ao realizar login!'
                });
            }

            if (resultado.length === 0) {
                return res.status(401).json({
                    erro: 'Email ou senha inválidos'
                });
            }

            const usuario = resultado[0];

            console.log('Email recebido:', email);
            console.log('Senha recebida:', senha);
            console.log('Hash no banco:', usuario.senha);

            const senhaCorreta = await bcrypt.compare(
                senha,
                usuario.senha
            );

            console.log('Senha corresponde ao hash?', senhaCorreta);

            if(!senhaCorreta) {
                return res.status(401).json({
                    erro: 'Email ou senha inválidos'
                });
            }

            const token = jwt.sign(
                {
                    usuario_id: usuario.usuario_id,
                    tipo_usuario: usuario.tipo_usuario
                },
                process.env.JWT_SECRET,
                {
                    expiresIn: '25m'
                }
            );

            res.status(200).json({
                usuario_id: usuario.usuario_id,
                nome: usuario.nome,
                email: usuario.email,
                tipo_usuario: usuario.tipo_usuario,
                token: token
            });
        }
    );
};
module.exports = {
    cadastrarUsuario,
    login
};