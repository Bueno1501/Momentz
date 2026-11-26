
const express = require('express');
const multer = require('multer');

const router = express.Router();

const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 10 * 1024 * 1024
    },
    fileFilter: (req, file, cb) => {

        console.log('Arquivo recebido na galeria', {
            nome: file.originalname,
            mimetype: file.mimetype
        });

        if (!file.mimetype.startsWith('image/')) {
            return cb(new Error('Envie somente arquivos de imagem'));
        }

        cb(null, true);
    }
});

const {
    cadastrarEvento,
    buscarEventoUsuario,
    acessarEvento,
    buscarEventoPorToken,
    importarConvite,
    importarFundoConvite,
    buscarEventoPorId
} = require('../controllers/eventosController');

const authAdminMiddleware = require('../middlewares/authAdminMiddleware');

const {
    cadastrarConvidadoPublico
} = require('../controllers/convidadosController');


router.post('/', authAdminMiddleware, cadastrarEvento);

router.get('/meus-eventos', authAdminMiddleware, buscarEventoUsuario);

router.put(
    '/:eventoId/convite',
    authAdminMiddleware,
    upload.single('convite'),
    importarConvite
);

router.put(
    '/:eventoId/fundo-convite',
    authAdminMiddleware,
    upload.single('fundo'),
    importarFundoConvite
);

router.get('/:eventoId', authAdminMiddleware, buscarEventoPorId);


router.post('/acessar', acessarEvento);

router.get('/convite/:token', buscarEventoPorToken);

router.post('/publico/:token', cadastrarConvidadoPublico);

module.exports = router;