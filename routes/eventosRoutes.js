
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

const {
    cadastrarConvidadoPublico
} = require('../controllers/convidadosController');

router.post('/', cadastrarEvento);
router.get('/', listarEvento);
router.get('/usuario/:usuarioId', buscarEventoUsuario);
router.post('/acessar', acessarEvento);
router.get('/convite/:token', buscarEventoPorToken);
router.put('/:eventoId/convite', upload.single('convite'), importarConvite);
router.get('/:eventoId', buscarEventoPorId);
router.post('/publico/:token', cadastrarConvidadoPublico);

module.exports = router;
