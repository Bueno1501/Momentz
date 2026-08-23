const express = require('express');

const router = express.Router();

const {
    cadastrarPresente,
    listarPresentes,
    listarPresentesEvento
} = require('../controllers/presentesController');

router.post('/', cadastrarPresente);

router.get('/', listarPresentes);
router.get('/evento/:eventoId', listarPresentesEvento);

module.exports = router;