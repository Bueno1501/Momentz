const express = require('express');
const multer = require('multer');


const router = express.Router();

const storage = multer.diskStorage({

    destination: (req, file, cb) => {
        cb(null, 'uploads/convites/');
    },

    filename: (req, file, cb) => {
        const nomeArquivo = Date.now() + '-' + file.originalname;

        cb(null, nomeArquivo);
    }
});

const upload = multer({
    storage
});

const{
    cadastrarEvento,
    listarEvento,
    buscarEventoUsuario,
    acessarEvento,
    buscarEventoPorToken,
    importarConvite
} =  require('../controllers/eventosController');

router.post('/', cadastrarEvento);
router.get('/', listarEvento);
router.get('/usuario/:usuarioId' , buscarEventoUsuario);
router.post('/acessar', acessarEvento);
router.get('/convite/:token', buscarEventoPorToken);
router.put('/:eventoId/convite', upload.single('convite'), importarConvite);
module.exports = router;