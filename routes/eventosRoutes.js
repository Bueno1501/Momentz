const express = require('express');

const router = express.Router();

const{
    cadastrarEvento,
    listarEvento,
    buscarEventoUsuario,
    acessarEvento,
    buscarEventoPorToken
} =  require('../controllers/eventosController');

router.post('/', cadastrarEvento);
router.get('/', listarEvento);
router.get('/usuario/:usuarioId' , buscarEventoUsuario);
router.post('/acessar', acessarEvento);
router.get('/convite/:token', buscarEventoPorToken);
module.exports = router;