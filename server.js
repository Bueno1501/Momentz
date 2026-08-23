require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');

const conexao = require('./config/db');
const fotosRoutes = require('./routes/fotosRoutes');
const usuraiosRoutes = require('./routes/usuariosRoutes');
const eventosRoutes = require('./routes/eventosRoutes');
const convidadosRoutes = require('./routes/convidadosRoutes');
const fornecedoresRoutes = require('./routes/fornecedoresRoutes');
const presentesRoutes = require('./routes/presentesRoutes');
const orcamentoRouter = require('./routes/orcamentoRoutes');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/usuarios', usuraiosRoutes);
app.use('/eventos', eventosRoutes);
app.use('/convidados', convidadosRoutes);
app.use('/fornecedores', fornecedoresRoutes);
app.use('/presentes', presentesRoutes);
app.use('/fotos', fotosRoutes);
app.use('/orcamento', orcamentoRouter);

app.get('/', (req, res) => {
    res.send('Momentz ON!');
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Servidor ta ON na porta ${PORT}`);
});