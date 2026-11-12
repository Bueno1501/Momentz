
const express = require('express');
const router = express.Router();

const authAdminMiddleware = require('../middlewares/authAdminMiddleware');

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

// ROTAS PÚBLICAS
router.get('/convite/:token', buscarConvitePorToken);
router.put('/convite/:token/status', responderConvite);

router.post('/enviar-codigo', enviarCodigoConvidado);
router.post('/validar-codigo', validarCodigoConvidado);
router.post('/renovar-sessao', renovarSessaoConvidado);
router.post('/logout', logoutConvidado);

// ROTAS ADMINISTRATIVAS
router.post('/', authAdminMiddleware, cadastrarConvidado);
router.get('/evento/:eventoId', authAdminMiddleware, listarConvidadosPorEvento);
router.put('/:convidadoId/status', authAdminMiddleware, alterarStatusConvidados);
router.delete('/:convidadoId', authAdminMiddleware, excluirConvidado);

module.exports = router;
