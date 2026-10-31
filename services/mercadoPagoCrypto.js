const crypto = require('crypto');

const ALGORITHM = 'aes-256-gcm';

function getEncryptionKey() {
    const keyHex = process.env.MP_TOKEN_ENCRYPTION_KEY;

    if (!keyHex || !/^[0-9a-fA-F]{64}$/.test(keyHex)) {
        throw new Error(
            'MP_TOKEN_ENCRYPTION_KEY ausente ou inválida.'
        );
    }

    return Buffer.from(keyHex, 'hex');
}

function criptografarToken(token) {
    if(typeof token !== 'string' || token.length === 0) {
        throw new Error('Token inválido para criptografia.')
    }

    const iv = crypto.randomBytes(12);

    const cipher = crypto.createCipheriv(
        ALGORITHM,
        getEncryptionKey(), iv
    );

    const encrypted = Buffer.concat([
        cipher.update(token, 'utf8'),
        cipher.final()
    ]);

    const authTag = cipher.getAuthTag();

    return [
        iv.toString('hex'),
        authTag.toString('hex'),
        encrypted.toString('hex'),
    ].join(':');
}

function descriptografarToken(tokenCriptografado) {
    if (typeof tokenCriptografado !== 'string') {
        throw new Error('Token criptografado inválido.');
    }

    const partes = tokenCriptografado.split(':');

    if (partes.length !== 3) {
        throw new Error('Formato de token criptografado inválido.');
    }

    const [ivHex, authTagHex, encryptedHex] = partes;
    
    if(
        !/^[0-9a-fA-F]{24}$/.test(ivHex) ||
        !/^[0-9a-fA-F]{32}$/.test(authTagHex) ||
        !/^(?:[0-9a-fA-F]{2})+$/.test(encryptedHex)
    ) {
        throw new Error('Dados criptografados inválidos.');
    }

    const decipher = crypto.createDecipheriv(
        ALGORITHM,
        getEncryptionKey(),
        Buffer.from(ivHex, 'hex')
    );

    decipher.setAuthTag(Buffer.from(authTagHex, 'hex'));

    const decrypted = Buffer.concat([
        decipher.update(Buffer.from(encryptedHex, 'hex')),
        decipher.final()
    ]);

    return decrypted.toString('utf8');
}

module.exports = {
    criptografarToken,
    descriptografarToken
};