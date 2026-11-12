
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
    listarEvento,
    buscarEventoUsuario,
    acessarEvento,
    buscarEventoPorToken,
    importarConvite,
    buscarEventoPorId
} = require('../controllers/eventosController');

const authAdminMiddleware = require('../middlewares/authAdminMiddleware');

const {
    cadastrarConvidadoPublico
} = require('../controllers/convidadosController');


// ROTAS ADMINISTRATIVAS
router.post('/', authAdminMiddleware, cadastrarEvento);

router.get('/meus-eventos', authAdminMiddleware, buscarEventoUsuario);

router.put(
    '/:eventoId/convite',
    authAdminMiddleware,
    upload.single('convite'),
    importarConvite
);

router.get('/:eventoId', authAdminMiddleware, buscarEventoPorId);


// ROTAS PÚBLICAS
router.post('/acessar', acessarEvento);

router.get('/convite/:token', buscarEventoPorToken);

router.post('/publico/:token', cadastrarConvidadoPublico);

module.exports = router;