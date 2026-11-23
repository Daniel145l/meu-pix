import { Conta } from "../../../domain/entities/Contas";

export interface ContaRepository {
  buscarPorId(id: string): Promise<Conta | null>
  buscarPorChavePix(chave: string): Promise<Conta | null>
  salvar(conta: Conta): Promise<void>
}