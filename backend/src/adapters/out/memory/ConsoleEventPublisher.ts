import { EventPublisher, PixTransferidoEvent } from "../../../application/ports/out/EventPublisher";

export class ConsoleEventPublisher implements EventPublisher {
  async publicarPixTransferido(evento: PixTransferidoEvent): Promise<void> {
    console.log("[EVENTO PUBLICADO - PixTransferido]:", JSON.stringify(evento));
  }
}