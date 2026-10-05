const nodemailer = require('nodemailer');


const transporter = nodemailer.createTransport({

    service: 'gmail',

    pool: true,
    maxConnections: 5,
    maxMessages: 100,

    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    }
});

async function enviarEmailBoasVindas(destinatario, nome){

    await transporter.sendMail({
        from: `"Momentz" <${process.env.EMAIL_USER}>`,

        to: destinatario,

        subject: '🎉 Bem-vindo ao Momentz!',

        html: `
        <div style="font-family: Arial; max-width:600px; margin:auto;">

            <h1 style="color:#8E24AA;">
                Bem-vindo ao Momentz!
            </h1>

            <p>Olá <strong>${nome}</strong>,</p>

            <p>
                Sua conta foi criada com sucesso!
            </p>

            <p>
                Agora você já pode acessar o sistema e aproveitar todos os recursos do Momentz.
            </p>

            <hr>

            <p style="color:gray;">
                Este e-mail foi enviado automaticamente.
            </p>

        </div>
        `
    });

}

module.exports = {
    enviarEmailBoasVindas
}