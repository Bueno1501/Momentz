const express = require( 'express');

const router = express.Router();

const {
    cadastrarFornecedor,
    listarFornecedores,
    listarFornecedoresEvento
} = require('../controllers/fornecedoresController');

router.post('/', cadastrarFornecedor);

router.get('/', listarFornecedores);
router.get('/evento/:eventoId', listarFornecedoresEvento);

module.exports = router;
