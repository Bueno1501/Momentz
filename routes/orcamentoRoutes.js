
const express = require('express');
const router = express.Router();

const {
    buscarOrcamento,
    atualizarOrcamento
} = require('../controllers/orcamentoController');

const authAdminMiddleware = require('../middlewares/authAdminMiddleware');

router.get('/:eventoId', authAdminMiddleware, buscarOrcamento);

router.put('/:eventoId', authAdminMiddleware, atualizarOrcamento);

module.exports = router;
