# Diagramas C4 — Meu Pix

A **fonte oficial** dos diagramas é o arquivo [`workspace.dsl`](../../workspace.dsl) (Structurizr DSL).
Os diagramas abaixo são uma **cópia em Mermaid** das mesmas visões, só para que possam ser lidos diretamente no GitHub.
Ao alterar a arquitetura, altere primeiro o `workspace.dsl` e depois replique aqui.

Como visualizar o DSL (Structurizr Lite), a partir da raiz do repositório:

```bash
docker run -it --rm -p 8080:8080 -v "$PWD":/usr/local/structurizr structurizr/lite
```

Depois é só abrir http://localhost:8080. Também dá para colar o conteúdo do `workspace.dsl` em https://structurizr.com/dsl.

---

## Nível 1 — Diagrama de Contexto

**Pergunta que responde:** *o que é o sistema, quem o usa e com quem ele conversa?*

```mermaid
flowchart LR
    usuario["👤 <b>Usuário do Banco</b><br/><i>[Pessoa]</i><br/>Consulta saldo e extrato, gerencia chaves PIX,<br/>transfere e recebe notificações"]
    meuPix["<b>Meu Pix</b><br/><i>[Sistema de Software]</i><br/>Carteira digital que simula contas,<br/>chaves PIX e transferências instantâneas"]
    spi["<b>Simulador SPI / DICT (BACEN)</b><br/><i>[Sistema Externo]</i><br/>Resolve chaves de outras instituições<br/>e liquida ordens PIX interbancárias"]

    usuario -- "Consulta saldo/extrato, gerencia<br/>chaves PIX e envia PIX" --> meuPix
    meuPix -- "Notifica operações concluídas" --> usuario
    meuPix -- "Resolve chaves de outras instituições<br/>e envia ordens PIX interbancárias" --> spi

    classDef person fill:#08427b,color:#fff,stroke:#052e56
    classDef system fill:#1168bd,color:#fff,stroke:#0b4884
    classDef external fill:#999999,color:#fff,stroke:#6b6b6b
    class usuario person
    class meuPix system
    class spi external
```

| Elemento | Tipo | Responsabilidade |
|---|---|---|
| Usuário do Banco | Pessoa | Correntista: consulta saldo/extrato, cadastra/remove chaves PIX, envia PIX e recebe notificações. |
| Meu Pix | Sistema (em foco) | Mantém contas, saldos, chaves PIX e transações e aplica as regras de negócio do PIX. |
| Simulador SPI / DICT (BACEN) | Sistema externo | Simula o diretório de chaves (DICT) e o sistema de liquidação (SPI) do Banco Central, usado quando a chave de destino é de outra instituição. |

---

## Nível 2 — Diagrama de Containers

**Pergunta que responde:** *quais são as partes executáveis do sistema, que tecnologia cada uma usa e como elas se comunicam?*

```mermaid
flowchart LR
    usuario["👤 <b>Usuário do Banco</b><br/><i>[Pessoa]</i>"]

    subgraph meuPix["Meu Pix [Sistema de Software]"]
        direction LR
        webapp["<b>Aplicação Web</b><br/><i>[Container: Vue.js / TypeScript]</i><br/>SPA: saldo, extrato, chaves,<br/>envio de PIX e notificações"]
        core{{"<b>Core Backend</b><br/><i>[Container: Node.js / Express / TypeScript]</i><br/>Núcleo hexagonal: API REST +<br/>regras de contas, chaves e PIX"}}
        broker[["<b>Message Broker</b><br/><i>[Container: RabbitMQ]</i><br/>Eventos de domínio<br/>(PixEnviado, PixRecebido...)"]]
        worker["<b>Serviço de Notificações</b><br/><i>[Container: Node.js Worker]</i><br/>Consome eventos e gera<br/>notificações/comprovantes"]
        db[("<b>Banco de Dados</b><br/><i>[Container: PostgreSQL / Supabase]</i><br/>Contas, chaves, transações<br/>e notificações")]
    end

    spi["<b>Simulador SPI / DICT (BACEN)</b><br/><i>[Sistema Externo]</i>"]

    usuario -- "Acessa pelo navegador<br/>[HTTPS]" --> webapp
    webapp -- "Chama a API<br/>[JSON/HTTPS - REST]" --> core
    core -- "Lê e grava contas, chaves<br/>e transações [SQL/TCP]" --> db
    core -- "Publica eventos de domínio<br/>[AMQP - assíncrono]" --> broker
    core -- "Consulta chave (DICT) e envia<br/>ordem (SPI) [JSON/HTTPS - síncrono]" --> spi
    worker -- "Consome PixEnviado / PixRecebido<br/>[AMQP - assíncrono]" --> broker
    worker -- "Registra notificações<br/>[SQL/TCP]" --> db
    worker -- "Envia notificação<br/>[In-app / E-mail simulado]" --> usuario

    classDef person fill:#08427b,color:#fff,stroke:#052e56
    classDef container fill:#438dd5,color:#fff,stroke:#2e6295
    classDef external fill:#999999,color:#fff,stroke:#6b6b6b
    class usuario person
    class webapp,core,broker,worker,db container
    class spi external
```

### Containers e responsabilidades

| Container | Tecnologia | Responsabilidade |
|---|---|---|
| Aplicação Web | Vue.js / TypeScript | Interface do usuário. Não tem regra de negócio: só chama a API REST. |
| Core Backend | Node.js / Express / TypeScript | **Hexágono** do sistema. Os controladores REST são *adaptadores de entrada*; o domínio (Conta, ChavePix, Transação) e os casos de uso ficam no centro; banco, SPI e broker são acessados por *portas de saída* implementadas por adaptadores. |
| Message Broker | RabbitMQ | Recebe os eventos de domínio publicados pelo Core e os entrega aos consumidores, de forma assíncrona. |
| Serviço de Notificações | Node.js Worker / TypeScript | Reage aos eventos `PixEnviado`/`PixRecebido`, gera o comprovante e notifica pagador e recebedor. |
| Banco de Dados | PostgreSQL (Supabase) | Persistência de contas, saldos, chaves PIX, transações e notificações. |

### Mecanismos de comunicação e fluxo de dados

| Origem → Destino | Mecanismo | Síncrono? | Por quê |
|---|---|---|---|
| Aplicação Web → Core Backend | REST, JSON sobre HTTPS | Sim | O usuário precisa da resposta na hora (saldo, comprovante). |
| Core Backend → Banco de Dados | SQL/TCP | Sim | O débito na origem e o crédito no destino precisam ser **atômicos** (mesma transação). |
| Core Backend → Simulador SPI/DICT | REST, JSON sobre HTTPS | Sim | Só conseguimos confirmar um PIX para outra instituição depois que o SPI liquida a ordem. |
| Core Backend → Message Broker | AMQP (publish) | **Não** | Notificar é consequência da transferência, não parte dela: se o envio da notificação falhar, o PIX não pode ser desfeito. |
| Serviço de Notificações → Message Broker | AMQP (consume) | **Não** | Permite adicionar outros consumidores (antifraude, auditoria) sem mexer no Core. |

**Fluxo principal — Enviar PIX (visão de containers):**

1. O usuário informa a chave de destino e o valor na **Aplicação Web**.
2. A Aplicação Web envia `POST /contas/{id}/pix` ao **Core Backend**.
3. O Core valida o valor e o saldo, e resolve a chave. Se a chave for do Meu Pix, busca no **Banco de Dados**; se não for, consulta o DICT no **Simulador SPI**.
4. O Core debita a origem e credita o destino na mesma transação (ou envia a ordem ao SPI, se o destino for externo) e grava a transação no extrato.
5. O Core devolve o comprovante ao usuário **e** publica `PixEnviado`/`PixRecebido` no **Message Broker**.
6. O **Serviço de Notificações** consome os eventos, registra as notificações no banco e avisa pagador e recebedor.

> Os diagramas de **Componentes** (nível 3) e **Código** (nível 4) ficam para a entrega de 23/11–24/11.
