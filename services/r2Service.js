
const {
    S3Client,
    PutObjectCommand,
    GetObjectCommand,
    DeleteObjectCommand
} = require('@aws-sdk/client-s3');

const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

const obrigatorias = [
    'R2_ACCESS_KEY_ID',
    'R2_SECRET_ACCESS_KEY',
    'R2_BUCKET_NAME',
    'R2_ENDPOINT'
];

const ausentes = obrigatorias.filter((nome) => !process.env[nome]);

if (ausentes.length > 0) {
    throw new Error(
        `Variáveis do R2 ausentes: ${ausentes.join(', ')}`
    );
}

const s3 = new S3Client({
    region: 'auto',
    endpoint: process.env.R2_ENDPOINT,
    credentials: {
        accessKeyId: process.env.R2_ACCESS_KEY_ID,
        secretAccessKey: process.env.R2_SECRET_ACCESS_KEY
    }
});

const bucket = process.env.R2_BUCKET_NAME;

async function enviarArquivo({ chave, buffer, tipoConteudo }) {
    await s3.send(new PutObjectCommand({
        Bucket: bucket,
        Key: chave,
        Body: buffer,
        ContentType: tipoConteudo
    }));

    return chave;
}

async function gerarUrlTemporaria(chave, validadeSegundos = 3600) {
    return getSignedUrl(
        s3,
        new GetObjectCommand({
            Bucket: bucket,
            Key: chave
        }),
        { expiresIn: validadeSegundos }
    );
}

async function excluirArquivos(chave) {
    await s3.send(new DeleteObjectCommand({
        Bucket: bucket,
        Key: chave
    }));
}

module.exports = {
    enviarArquivo,
    gerarUrlTemporaria,
    excluirArquivos
};
