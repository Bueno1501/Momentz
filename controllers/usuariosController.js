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

const cadastrarConvidadoComConta = async (req, res) => {

    const {
        nome,
        email,
        senha,
        evento_id
    } = req.body;

    if (!nome || !email || !senha || !evento_id) {
        return res.status(400).json({
            erro: 'Nome, email , senha e evento são obroigatórios'
        });
    }

    try {

        const sqlEvento = `
            SELECT evento_id
            FROM evento
            WHERE evento_id = ?
        `;

        conexao.query(
            sqlEvento, [evento_id], async (erroEvento, resultadoEvento) => {

                if (erroEvento) {
                    console.log(erroEvento);

                    return res.status(500).json({
                        erro: 'Erro ao verificar evento'
                    });
                }

                if (resultadoEvento.length === 0) {
                    return res.status(400).json({
                        erro: 'Evento não encontrado'
                    });
                }

                const sqlUsuario = `
                    SELECT usuario_id
                    FROM usuario
                    WHERE email =?
                `;

                conexao.query(
                    sqlUsuario, [email], async (erroUsuario, resultadoUsuario) => {

                        if (erroUsuario) {
                            console.log(erroUsuario);

                            return res.status(500).json({
                                erro: 'Erro ao verificar usuário'
                            });
                        }

                        if (resultadoUsuario.length > 0) {
                            return res.status(409).json({
                                erro: 'Este email já possui uma conta. Faça login.'
                            });
                        }

                        const senhaHash = await bcrypt.hash(senha, 10);

                        const sqlCriaUsuario = `
                            INSERT INTO usuario
                            (nome, email, senha, tipo_usuario)
                            VALUES (?, ?, ?, 'Convidado')
                        `;

                        conexao.query(
                            sqlCriaUsuario,[nome, email, senhaHash], async (erroCriarUsuario, resultadoCriarUsuario) => {

                                if (erroCriarUsuario) {
                                    console.log(erroCriarUsuario);

                                    return res.status(500).json({
                                        erro: 'Erro ao criar conta do convidado'
                                    });
                                }

                                const usuarioId = resultadoCriarUsuario.insertId;

                                const sqlConvidado =`
                                    SELECT convidado_id
                                    FROM convidado
                                    WHERE email = ?
                                    AND evento_id = ?
                                `;

                                conexao.query(
                                    sqlConvidado,[email, evento_id], async (erroConvidado, resultadoConvidado) => {

                                        if (erroConvidado) {
                                            console.log(erroConvidado);

                                            return res.status(500).json({
                                                erro: 'Erro ao verificar convidado'
                                            });
                                        }

                                        if (resultadoConvidado.length > 0) {

                                            const convidadoId = resultadoConvidado[0].convidado_id;

                                            const sqlVincular = `
                                                UPDATE convidado 
                                                SET usuario_id = ?
                                                WHERE convidado_id = ?
                                            `;

                                            conexao.query(
                                                sqlVincular, [usuarioId, convidadoId], async (erroVincular) => {

                                                    if (erroVincular) {
                                                        console.log(erroVincular);

                                                        return res.status(500).json({
                                                            erro: 'Erro ao vincular conta ao convidado'
                                                        });
                                                    }

                                                    try {
                                                        await enviarEmailBoasVindas(
                                                            email,
                                                            nome
                                                        );
                                                    } catch (erroEmail) {
                                                        console.log(
                                                            'Erro ao enviar e-mail:'
                                                        );
                                                        console.log(erroEmail)
                                                    }

                                                    return res.status(201).json({
                                                        mensagem: 'Conta de convidado criada com sucesso',
                                                        usuarioId: usuarioId,
                                                        convidadoId: convidadoId
                                                    });
                                                }
                                            );
                                        } else {
                                            const sqlCriarConvidado = `
                                                INSERT INTO convidado
                                                (nome, email, evento_id, usuario_id, status_confirmacao)
                                                VALUES (?, ?, ?, ?, 'PENDENTE')
                                            `;

                                            conexao.query(
                                                sqlCriarConvidado,
                                                [
                                                    nome,
                                                    email,
                                                    evento_id,
                                                    usuarioId
                                                ],
                                                async (erroNovoConvidado, resultadoNovoConvidado) => {

                                                    if (erroNovoConvidado) {
                                                        console.log(erroNovoConvidado);

                                                        return res.status(500).json({
                                                            erro: 'Erro ao criar convidado'
                                                        });
                                                    } try {
                                                        await enviarEmailBoasVindas (
                                                            email,
                                                            nome
                                                        );
                                                    } catch (erroEmail) {
                                                        console.log('Erro ao enviar e-mail:');

                                                        console.log(erroEmail);
                                                    }

                                                    return res.status(201).json({
                                                        mensagem: 'Conta de convidado criada com sucesso',
                                                        usuarioId: usuarioId,
                                                        convidadoId: resultadoNovoConvidado.insertId
                                                    });
                                                }
                                            );
                                        }
                                    }
                                );
                            }
                        );
                    }
                );
            }
        );
    } catch (erro) {

        console.log(erro);

        return res.status(500).json({
            erro: 'Erro ao cadastrar convidado'
        });
    }
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
    cadastrarConvidadoComConta,
    login
};