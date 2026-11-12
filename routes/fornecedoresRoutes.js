const express = require("express");
const router = express.Router();

const {
  cadastrarFornecedor,
  listarFornecedoresEvento,
} = require("../controllers/fornecedoresController");

const authAdminMiddleware = require("../middlewares/authAdminMiddleware");

router.post("/", authAdminMiddleware, cadastrarFornecedor);

router.get("/evento/:eventoId", authAdminMiddleware, listarFornecedoresEvento);

module.exports = router;
