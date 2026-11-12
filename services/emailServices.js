
const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);

const remetente =
    process.env.RESEND_FROM_EMAIL ||
    'Momentz <noreply@momentz.pro>';

async function enviarEmailBoasVindas(destinatario, nome) {
    const { data, error } = await resend.emails.send({
        from: remetente,
        to: destinatario,
        subject: '🎉 Bem-vindo ao Momentz!',
        html: `
            <div style="font-family: Arial; max-width:600px; margin:auto;">
                <h1 style="color:#8E24AA;">
                    Bem-vindo ao Momentz!
                </h1>

                <p>Olá <strong>${nome}</strong>,</p>

                <p>Sua conta foi criada com sucesso!</p>

                <p>
                    Agora você já pode acessar o sistema
                    e aproveitar todos os recursos do Momentz.
                </p>

                <hr>

                <p style="color:gray;">
                    Este e-mail foi enviado automaticamente.
                </p>
            </div>
        `
    });

    if (error) {
        console.error('Erro Resend:', error);
        throw new Error('Não foi possível enviar o e-mail de boas-vindas.');
    }

    return data;
}

async function enviarCodigoVerificacao(destinatario, codigo) {
    const { data, error } = await resend.emails.send({
        from: remetente,
        to: destinatario,
        subject: 'Código de acesso - Momentz',
        html: `
            <div style="font-family: Arial; max-width:600px; margin:auto;">
                <h1 style="color:#8E24AA;">
                    Confirme seu acesso!
                </h1>

                <p>Utilize o código abaixo para acessar seu evento:</p>

                <h2 style="color:#8E24AA; letter-spacing:8px;">
                    ${codigo}
                </h2>

                <p>Este código expira em 5 minutos.</p>

                <p>
                    Se você não solicitou este acesso,
                    ignore este e-mail.
                </p>
            </div>
        `
    });

    if (error) {
        console.error('Erro Resend:', error);
        throw new Error('Não foi possível enviar o e-mail de verificação.');
    }

    return data;
}

module.exports = {
    enviarEmailBoasVindas,
    enviarCodigoVerificacao
};
