import express from "express";
import { TransferenciaController } from "./adapters/in/http/TransferenciaController";
import { ConsoleEventPublisher } from "./adapters/out/memory/ConsoleEventPublisher";
import { InMemoryContaRepository } from "./adapters/out/memory/InMemoryContaRepository";
import { RealizarTransferenciaPixUseCase } from "./application/use-cases/RealizarTransferenciaPixUseCase";

const app = express();
app.use(express.json());

// Composição das dependências (Arquitetura Hexagonal)
const contaRepository = new InMemoryContaRepository();
const eventPublisher = new ConsoleEventPublisher();
const realizarTransferenciaUseCase = new RealizarTransferenciaPixUseCase(
  contaRepository,
  eventPublisher
);
const transferenciaController = new TransferenciaController(realizarTransferenciaUseCase);

app.post("/pix/transferencias", (req, res) => transferenciaController.criar(req, res));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor Meu Pix rodando em http://localhost:${PORT}`);
});