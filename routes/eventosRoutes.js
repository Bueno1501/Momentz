const express = require('express');

const router = express.Router();

const{
    cadastrarEvento,
    listarEvento,
    buscarEventoUsuario,
    acessarEvento
} =  require('../controllers/eventosController');

router.post('/', cadastrarEvento);
router.get('/', listarEvento);
router.get('/usuario/:usuarioId' , buscarEventoUsuario);
router.post('/acessar', acessarEvento);
module.exports = router;