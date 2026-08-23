const express = require ('express');
const router = express.Router();
const multer = require('multer');

const { 
    uploadFoto,
    listarFotosPorEvento
 } = require('../controllers/fotosController');

const storage = multer.diskStorage({

    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },

    filename: (req, file, cb) => {
        const nomeArquivo = Date.now() + '-' + file.originalname;

        cb(null, nomeArquivo);
    }
});

const upload = multer ({
    storage
});

router.post('/', upload.single('foto'), uploadFoto );

router.get('/evento/:eventoId', listarFotosPorEvento);

module.exports = router;