
const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const authConvidadoMiddleware = require('../middlewares/authConvidadoMiddleware');

const {
    cadastrarPresente,
    listarPresentesEvento,
    listarPresentesConvidado,
    editarPresente,
    excluirPresente
} = require('../controllers/presentesController');

// Administrador
router.post('/', authMiddleware, cadastrarPresente);

router.get(
    '/evento/:eventoId',
    authMiddleware,
    listarPresentesEvento
);

router.put('/:presenteId', authMiddleware, editarPresente);

router.delete('/:presenteId', authMiddleware, excluirPresente);

// Convidado
router.get(
    '/convidado',
    authConvidadoMiddleware,
    listarPresentesConvidado
);

module.exports = router;
