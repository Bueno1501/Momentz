
const authMiddleware = require('./authMiddleware');

const authAdminMiddleware = (req, res, next) => {
    authMiddleware(req, res, () => {

        if (
            !req.usuario ||
            !req.usuario.usuario_id ||
            req.usuario.tipo_usuario !== 'Administrador'
        ) {
            return res.status(403).json({
                erro: 'Acesso permitido somente para administradores.'
            });
        }

        next();
    });
};

module.exports = authAdminMiddleware;
