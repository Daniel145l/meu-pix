import { ContaRepository } from "../../../application/ports/out/ContaRepository";
import { Conta } from "../../../domain/entities/Contas";

export class InMemoryContaRepository implements ContaRepository {
  private contas = new Map<string, Conta>();
  private chavesPix = new Map<string, string>();

  constructor() {
    //!para testes
    const conta1 = new Conta("conta-1", "Ana Silva", 1000);
    const conta2 = new Conta("conta-2", "Carlos Souza", 250);

    this.contas.set(conta1.id, conta1);
    this.contas.set(conta2.id, conta2);
    this.chavesPix.set("ana@email.com", conta1.id);
    this.chavesPix.set("carlos@email.com", conta2.id);
  }

  async buscarPorId(id: string): Promise<Conta | null> {
    return this.contas.get(id) ?? null;
  }

  async buscarPorChavePix(chave: string): Promise<Conta | null> {
    const contaId = this.chavesPix.get(chave);
    if (!contaId) return null;
    return this.buscarPorId(contaId);
  }

  async salvar(conta: Conta): Promise<void> {
    this.contas.set(conta.id, conta);
  }
}