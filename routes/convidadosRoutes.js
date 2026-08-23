const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');


const {
    cadastrarConvidado,
    listarConvidadosPorEvento,
    alterarStatusConvidados,
    excluirConvidado
} = require('../controllers/convidadosController');

router.post('/', authMiddleware, cadastrarConvidado);

router.get('/evento/:eventoId', authMiddleware, listarConvidadosPorEvento);

router.put('/:convidadoId/status', authMiddleware, alterarStatusConvidados);

router.delete('/:convidadoId', authMiddleware, excluirConvidado);

module.exports = router;