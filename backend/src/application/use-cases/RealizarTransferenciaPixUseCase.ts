import { ContaRepository } from "../ports/out/ContaRepository";
import { EventPublisher } from "../ports/out/EventPublisher";

export interface RealizarTransferenciaInput {
  contaOrigemId: string;
  chaveDestino: string;
  valor: number;
}

export class RealizarTransferenciaPixUseCase {
  constructor (
    private readonly contaRepository: ContaRepository,
    private readonly eventPublisher: EventPublisher
  ) {}

  async executar(input: RealizarTransferenciaInput) {
    const contaOrigem = await this.contaRepository.buscarPorId(input.contaOrigemId);
    if(!contaOrigem) {
      throw new Error("Conta não encontrada")
    }

    const contaDestino = await this.contaRepository.buscarPorChavePix(input.chaveDestino)
    if(!contaDestino) {
      throw new Error("Conta destino não encontrada")
    }

    if(contaOrigem.id === contaDestino.id) {
      throw new Error("Não é possível transferências para uma mesma conta")
    }

    contaOrigem.debitar(input.valor);
    contaDestino.creditar(input.valor);

    await this.contaRepository.salvar(contaOrigem);
    await this.contaRepository.salvar(contaDestino);

    await this.eventPublisher.publicarPixTransferido({
      origemId: contaOrigem.id,
      destinoId: contaDestino.id,
      chaveDestino: input.chaveDestino,
      valor: input.valor,
      dataHora: new Date().toISOString(),
    });

    return {
      status: "CONCLUIDA",
      origemId: contaOrigem.id,
      destinoId: contaDestino.id,
      valor: input.valor,
      saldoOrigemAtual: contaOrigem.saldo,
    };
  }
}