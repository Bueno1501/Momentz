const express = require('express');

const router = express.Router();

const{
    cadastrarEvento,
    listarEvento,
    buscarEventoUsuario
} =  require('../controllers/eventosController');

router.post('/', cadastrarEvento);
router.get('/', listarEvento);
router.get('/usuario/:usuarioId' , buscarEventoUsuario);
module.exports = router;