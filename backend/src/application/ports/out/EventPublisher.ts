export interface PixTransferidoEvent {
  origemId: string;
  destinoId: string;
  chaveDestino: string;
  valor: number;
  dataHora: string;
}

export interface EventPublisher {
  publicarPixTransferido(evento: PixTransferidoEvent): Promise<void>;
}