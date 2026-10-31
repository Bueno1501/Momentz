const express = require('express');

const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');

const {
    conectarMercadoPago,
    callbackMercadoPago
} = require('../controllers/mercadoPagoController');

router.post('/conectar', authMiddleware, conectarMercadoPago);

router.get('/oauth/callback', callbackMercadoPago);

module.exports = router;