
const express = require('express');
const router = express.Router();

const authMiddleware = require(
  '../middlewares/authMiddleware'
);

const authConvidadoMiddleware = require(
  '../middlewares/authConvidadoMiddleware'
);

const {
  criarCheckoutPresente,
  receberWebhookMercadoPago
} = require('../controllers/pagamentosController');

const {
  criarPagamentoPix
} = require('../controllers/pagamentoPixController');

const {
  reconciliarPagamento
} = require('../controllers/reconciliacaoPagamentosController');



router.post(
  '/checkout/presente',
  authConvidadoMiddleware,
  criarCheckoutPresente
);



router.post(
  '/pix',
  authConvidadoMiddleware,
  criarPagamentoPix
);



router.post(
  '/admin/reconciliar/:pagamentoId',
  authMiddleware,
  reconciliarPagamento
);


router.post(
  '/webhook',
  receberWebhookMercadoPago
);

module.exports = router;
