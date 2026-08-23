const express = require('express');

const router = express.Router();

const {
    buscarOrcamento,
    atualizarOrcamento
} = require('../controllers/orcamentoController');

router.get('/:eventoId', buscarOrcamento);
router.put('/:eventoId', atualizarOrcamento);

module.exports = router;