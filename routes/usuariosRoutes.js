const express = require('express');

const router = express.Router();

const {
    cadastrarUsuario,
    login
} = require('../controllers/usuariosController');

router.get('/', (req, res) => {
    res.send('Rota de usuários ta nice!');
});

router.post('/', cadastrarUsuario);
router.post('/login', login);

module.exports = router;