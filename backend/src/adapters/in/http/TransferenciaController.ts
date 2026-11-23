import { Request, Response } from "express";
import { RealizarTransferenciaPixUseCase } from "../../../application/use-cases/RealizarTransferenciaPixUseCase";

export class TransferenciaController {
  constructor(
    private readonly realizarTransferenciaPixUseCase: RealizarTransferenciaPixUseCase
  ) {}

  async criar(req: Request, res: Response): Promise<Response> {
    try {
      const { contaOrigemId, chaveDestino, valor } = req.body;

      const resultado = await this.realizarTransferenciaPixUseCase.executar({
        contaOrigemId,
        chaveDestino,
        valor: Number(valor),
      });

      return res.status(201).json(resultado);
    } catch (error) {
      const mensagem = error instanceof Error ? error.message : "Erro inesperado.";
      return res.status(400).json({ erro: mensagem });
    }
  }
}