
const express = require('express');
const router = express.Router();

const authConvidadoMiddleware = require(
    '../middlewares/authConvidadoMiddleware'
);

const {
    criarCheckoutPresente,
    receberWebhookMercadoPago
} = require('../controllers/pagamentosController');

// Checkout: exige sessão válida do convidado.
router.post(
    '/checkout/presente',
    authConvidadoMiddleware,
    criarCheckoutPresente
);

// Webhook: acesso público, mas com assinatura obrigatória.
router.post(
    '/webhook',
    receberWebhookMercadoPago
);

module.exports = router;
