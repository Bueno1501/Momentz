
const express = require('express');
const router = express.Router();

const authConvidadoMiddleware = require(
    '../middlewares/authConvidadoMiddleware'
);

const {
    criarCheckoutPresente,
    receberWebhookMercadoPago
} = require('../controllers/pagamentosController');

const {
  criarPagamentoPix
} = require("../controllers/pagamentoPixController");

router.post(
    '/checkout/presente',
    authConvidadoMiddleware,
    criarCheckoutPresente
);

router.post(
  "/pix",
  authConvidadoMiddleware,
  criarPagamentoPix
);

router.post(
    '/webhook',
    receberWebhookMercadoPago
);

module.exports = router;
