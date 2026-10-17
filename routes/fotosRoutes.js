const express = require ('express');
const multer = require('multer');

const router = express.Router();


const { 
    uploadFoto,
    listarFotosPorEvento
 } = require('../controllers/fotosController');

const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 10 * 1024 * 1024
    },
    fileFilter: (req, file, cb) => {
        if(!file.mimetype.startsWith('image/')) {
            return cb(new Error('Envie somente arquivos de imagem'));
        }

        cb(null, true);
    }
});

router.post('/', upload.single('foto'), uploadFoto );

router.get('/evento/:eventoId', listarFotosPorEvento);

module.exports = router;