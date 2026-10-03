const express = require('express');

const router = express.Router();

const {
    cadastrarUsuario,
    cadastrarConvidadoComConta,
    login
} = require('../controllers/usuariosController');

router.get('/', (req, res) => {
    res.send('Rota de usuários ta nice!');
});

router.post('/', cadastrarUsuario);
router.post('/convidado', cadastrarConvidadoComConta);
router.post('/login', login);

module.exports = router;