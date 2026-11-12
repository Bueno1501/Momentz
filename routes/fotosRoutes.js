
const express = require('express');
const multer = require('multer');

const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const authConvidadoMiddleware = require('../middlewares/authConvidadoMiddleware');

const {
    uploadFotosConvidado,
    uploadFotosAdministrador,
    listarFotosConvidado,
    listarFotosAdministrador
} = require('../controllers/fotosController');


const configurarUpload = (limiteFotos) => {
    return multer({
        storage: multer.memoryStorage(),

        limits: {
            fileSize: 10 * 1024 * 1024,
            files: limiteFotos
        },

        fileFilter: (req, file, cb) => {
            const tiposPermitidos = [
                'image/jpeg',
                'image/png',
                'image/webp',
                'image/gif'
            ];

            if (!tiposPermitidos.includes(file.mimetype)) {
                return cb(new Error('Formato de imagem não permitido.'));
            }

            cb(null, true);
        }
    });
};

const uploadConvidado = configurarUpload(5);

const uploadAdministrador = configurarUpload(25);


router.post(
    '/convidado/upload',
    authConvidadoMiddleware,
    uploadConvidado.array('fotos', 5),
    uploadFotosConvidado
);

router.get(
    '/convidado/minhas',
    authConvidadoMiddleware,
    listarFotosConvidado
);


router.post(
    '/admin/:eventoId/upload',
    authMiddleware,
    uploadAdministrador.array('fotos', 20),
    uploadFotosAdministrador
);

router.get(
    '/admin/evento/:eventoId',
    authMiddleware,
    listarFotosAdministrador
);

module.exports = router;
