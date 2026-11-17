# Documento de Decisões Arquiteturais — Meu Pix

Cada decisão segue o formato de **ADR** (*Architecture Decision Record*): contexto, decisão, alternativas consideradas e consequências.
Este documento acompanha o projeto e ganha novas ADRs a cada entrega.

| ADR | Título | Status | Data |
|---|---|---|---|
| [001](#adr-001--estilo-arquitetural-principal-hexagonal-ports-and-adapters) | Estilo arquitetural principal: Hexagonal (Ports and Adapters) | Aceita | 17/11/2026 |
| [002](#adr-002--event-driven-como-estilo-complementar-para-notificações) | Event-Driven como estilo complementar para notificações | Aceita | 17/11/2026 |
| [003](#adr-003--documentação-com-modelo-c4-em-structurizr-dsl) | Documentação com Modelo C4 em Structurizr DSL | Aceita | 17/11/2026 |
| [004](#adr-004--stack-tecnológica) | Stack tecnológica | Aceita | 17/11/2026 |
| [005](#adr-005--integração-com-o-spidict-por-meio-de-um-simulador) | Integração com o SPI/DICT por meio de um simulador | Aceita | 17/11/2026 |

---

## ADR-001 — Estilo arquitetural principal: Hexagonal (Ports and Adapters)

**Contexto.**
O domínio sorteado foi *Sistema Bancário e PIX*, para o qual a especificação indica como adequados: Clean Architecture, Hexagonal, Event-Driven e Serverless.
As regras centrais (saldo suficiente, débito/crédito atômico, validação e unicidade de chaves PIX) são estáveis. Já as tecnologias ao redor mudam: interface (web hoje, talvez mobile amanhã), banco de dados e principalmente a integração com o SPI/BACEN, que neste projeto é **simulada** e um dia poderia ser real.

**Decisão.**
O sistema segue **majoritariamente a Arquitetura Hexagonal**. O Core Backend fica organizado assim:
- **Centro (domínio + casos de uso):** `Conta`, `ChavePix`, `Transacao` e os casos de uso (consultar saldo, cadastrar chave, realizar transferência PIX...). Não importa Express, SQL nem bibliotecas de mensageria.
- **Portas de entrada:** interfaces dos casos de uso, chamadas pelos adaptadores REST.
- **Portas de saída:** `ContaRepository`, `ChavePixRepository`, `TransacaoRepository`, `SpiGateway` e `EventPublisher`.
- **Adaptadores:** REST/Express (entrada); PostgreSQL, cliente HTTP do simulador SPI e publicador RabbitMQ (saída).

**Alternativas consideradas.**
- *Clean Architecture:* tem o mesmo objetivo (regra de dependência apontando para dentro), mas com mais camadas prescritas (entities, use cases, interface adapters, frameworks). Para o tamanho do projeto, a separação em portas e adaptadores é mais direta e mais fácil de mostrar no diagrama de componentes.
- *Serverless:* bom para escalar sob demanda, mas a transferência precisa de transação atômica e estado consistente de saldo. Isso complica com funções efêmeras e dificulta rodar e demonstrar localmente em sala.
- *Camadas tradicionais (MVC):* tende a acoplar regra de negócio a framework e banco. É justamente o problema que a disciplina mostrou com o *Big Ball of Mud*.

**Consequências.**
- ✅ Regras de negócio testáveis sem banco nem servidor, trocando os adaptadores reais por adaptadores em memória.
- ✅ Trocar o simulador SPI por uma integração real, ou PostgreSQL por outro banco, exige só um novo adaptador.
- ⚠️ Mais interfaces e mais código "de ligação" (*boilerplate*) do que num CRUD simples. Essa é a desvantagem apontada em aula ("complexidade inicial").

---

## ADR-002 — Event-Driven como estilo complementar para notificações

**Contexto.**
A especificação exige que o usuário *receba notificações de operações concluídas*. Notificar é uma **consequência** da transferência, e não parte dela: se o envio da notificação falhar, o PIX não deve ser desfeito nem ficar lento.
A versão inicial do diagrama de containers mostrava o Core Backend "disparando eventos" direto para o Serviço de Notificações, sem dizer por qual mecanismo.

**Decisão.**
Combinar Hexagonal + Event-Driven, como no exemplo "Event-Driven + Hexagonal" visto em aula:
- O Core publica **eventos de domínio** (`PixEnviado`, `PixRecebido`) por meio da porta de saída `EventPublisher`.
- Um **Message Broker (RabbitMQ)** foi adicionado como container explícito, usando a **topologia broker**: não há orquestrador central, os consumidores se inscrevem nos eventos que interessam.
- O **Serviço de Notificações** é um consumidor assíncrono desses eventos.

**Alternativas consideradas.**
- *Chamada HTTP síncrona do Core para o Serviço de Notificações:* mais simples, mas acopla a disponibilidade dos dois e deixa a transferência esperando pela notificação.
- *Topologia mediator:* faria sentido se a transferência tivesse várias etapas a orquestrar. Como hoje há um único tipo de reação (notificar), o broker é suficiente.

**Consequências.**
- ✅ Novos consumidores (antifraude, auditoria, extrato analítico) podem ser adicionados sem alterar o Core.
- ✅ Falha ou lentidão no Serviço de Notificações não afeta a transferência.
- ⚠️ Consistência eventual: a notificação pode chegar alguns instantes depois do comprovante.
- ⚠️ Risco de o evento se perder se o Core gravar a transação e cair antes de publicar. A mitigação (padrão *Transactional Outbox*) será avaliada na implementação.

---

## ADR-003 — Documentação com Modelo C4 em Structurizr DSL

**Contexto.**
A especificação exige documentação segundo o modelo C4 com Structurizr, com diagramas de todas as visões no GitHub.

**Decisão.**
- Manter um único modelo em [`workspace.dsl`](../workspace.dsl) (*diagrams as code*). As visões (Contexto, Containers e, nas próximas entregas, Componentes) são geradas a partir dele.
- Usar `!identifiers hierarchical` para referenciar containers como `meuPix.coreBackend`, o que evita conflito de nomes quando entrarem os componentes.
- Indicar a **tecnologia e o mecanismo** (REST/HTTPS, SQL, AMQP, síncrono/assíncrono) em cada relacionamento, como pede a especificação ("definição clara dos mecanismos de comunicação").
- Manter uma cópia em Mermaid em [`docs/diagramas/README.md`](diagramas/README.md) para leitura direta no GitHub.

**Consequências.**
- ✅ Diagramas versionados junto com o código, revisáveis em Pull Request e sem divergência entre visões, porque todas vêm do mesmo modelo.
- ⚠️ A cópia em Mermaid precisa ser atualizada manualmente quando o DSL mudar.

---

## ADR-004 — Stack tecnológica

**Contexto.**
O time precisa de uma stack conhecida, que rode fácil localmente e tenha tipagem estática para deixar as portas explícitas.

**Decisão.**

| Container | Tecnologia |
|---|---|
| Aplicação Web | Vue.js + TypeScript |
| Core Backend | Node.js + Express + TypeScript |
| Serviço de Notificações | Node.js Worker + TypeScript |
| Message Broker | RabbitMQ |
| Banco de Dados | PostgreSQL (Supabase) |

**Justificativa.**
Com TypeScript, as portas viram `interface`s verificadas pelo compilador. Assim, um adaptador que não implemente a porta corretamente não compila.
Uma só linguagem no front e no back também reduz o custo de troca de contexto do time.
PostgreSQL garante transações ACID, necessárias para o débito e o crédito atômicos.

**Consequências.**
- ⚠️ Express não impõe estrutura nenhuma. Por isso o time precisa cuidar para que nada do Express "vaze" para o domínio, e isso será conferido no diagrama de componentes.

---

## ADR-005 — Integração com o SPI/DICT por meio de um simulador

**Contexto.**
Integrar com o SPI/DICT real do Banco Central exige credenciamento como instituição de pagamento, o que é impossível num projeto acadêmico.

**Decisão.**
Modelar o SPI/DICT como **sistema externo simulado**, acessado exclusivamente pela porta de saída `SpiGateway`, que tem duas operações:
- consultar uma chave em outra instituição (DICT);
- enviar uma ordem de pagamento (SPI).

Transferências entre contas do próprio Meu Pix são liquidadas internamente, sem passar pelo SPI.

**Consequências.**
- ✅ Demonstra concretamente a vantagem da Hexagonal: o simulador pode ser trocado por uma integração real só com um novo adaptador.
- ✅ O simulador pode forçar cenários de erro (chave inexistente, ordem rejeitada) para testes e apresentação.
