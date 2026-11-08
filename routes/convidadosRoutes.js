const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');


const {
    cadastrarConvidado,
    listarConvidadosPorEvento,
    alterarStatusConvidados,
    excluirConvidado,
    buscarConvitePorToken,
    responderConvite,
    enviarCodigoConvidado,
    validarCodigoConvidado,
    renovarSessaoConvidado,
    logoutConvidado
} = require('../controllers/convidadosController');

router.get('/convite/:token', buscarConvitePorToken);

router.put('/convite/:token/status', responderConvite);

router.post('/', authMiddleware, cadastrarConvidado);

router.post('/enviar-codigo', enviarCodigoConvidado);

router.post('/validar-codigo', validarCodigoConvidado);

router.post('/renovar-sessao', renovarSessaoConvidado);

router.post('/logout', logoutConvidado);

router.get('/evento/:eventoId', authMiddleware, listarConvidadosPorEvento);

router.put('/:convidadoId/status', authMiddleware, alterarStatusConvidados);

router.delete('/:convidadoId', authMiddleware, excluirConvidado);

module.exports = router;