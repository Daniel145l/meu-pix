# Meu Pix - Sistema Bancário e PIX

Repositório oficial do projeto final da disciplina de **Arquitetura de Software**, desenvolvido com foco no domínio de **Sistema Bancário e PIX**.

## Sobre o Projeto

O **Meu Pix** é uma aplicação de simulação de carteira digital e pagamentos instantâneos. O sistema foi projetado para permitir que usuários gerenciem suas contas, realizem consultas de saldo, cadastrem e gerenciem chaves PIX, além de efetuar transferências instantâneas de forma segura, rápida e desacoplada.

## Estilo Arquitetural: Arquitetura Hexagonal (Ports and Adapters) + Event-Driven

O projeto adota **majoritariamente os princípios da Arquitetura Hexagonal**. A **Arquitetura Baseada em Eventos** entra como estilo complementar, só para as notificações.

* **Por que Hexagonal?** O núcleo de negócio (domínio PIX, regras de transferência e validações de saldo) fica completamente isolado de detalhes tecnológicos externos, como frameworks web, bancos de dados ou integrações de APIs de terceiros. O núcleo só conversa com o exterior por **portas** (interfaces), que são implementadas por **adaptadores**.
  * Portas de entrada: casos de uso (consultar saldo, cadastrar chave, realizar transferência PIX...), chamados pelo adaptador REST.
  * Portas de saída: `ContaRepository`, `ChavePixRepository`, `TransacaoRepository`, `SpiGateway` e `EventPublisher`.

* **Por que Event-Driven para as notificações?** Notificar é consequência da transferência, e não parte dela. O Core publica eventos de domínio (`PixEnviado`, `PixRecebido`) num Message Broker e o Serviço de Notificações os consome de forma assíncrona. Assim, uma falha na notificação não desfaz nem atrasa o PIX.

* **Vantagens:** Facilidade para criar testes automatizados, flexibilidade para alterar adaptadores de entrada (REST APIs) e de saída (Persistence/SPI do BACEN) sem impactar as regras centrais da aplicação, e novos consumidores de eventos (ex.: antifraude) sem alterar o núcleo.

As justificativas completas, com as alternativas descartadas, estão no [Documento de Decisões Arquiteturais](docs/DECISOES-ARQUITETURAIS.md).

## Funcionalidades Desenvolvidas

O escopo funcional implementado e documentado compreende:

1. **Gerenciamento de Contas e Saldo:**
   * Cadastro e autenticação básica de usuários e contas correntes.
   * Consulta de saldo em tempo real e visualização de histórico/extrato de transações.

2. **Gerenciamento de Chaves PIX:**
   * Cadastro de chaves PIX vinculadas à conta (CPF, E-mail, Telefone, Chave Aleatória).
   * Listagem e exclusão de chaves ativas do usuário.

3. **Realização de Transferência PIX:**
   * Envio de valores consultando a chave de destino.
   * Validação de saldo suficiente e efetivação atômica da transação (débito na origem e crédito no destino).

4. **Notificações de Operações:**
   * Geração de recibos e notificações simuladas de operações concluídas com sucesso.

## Modelagem Arquitetural (C4 Model & Structurizr)

Seguindo as exigências do trabalho, a arquitetura do sistema está documentada com o **Modelo C4, em código, usando Structurizr DSL**.

* Fonte dos diagramas: [`workspace.dsl`](workspace.dsl), na raiz do repositório.
* Diagramas renderizados no GitHub (Mermaid), com tabelas de responsabilidades e mecanismos de comunicação: [`docs/diagramas`](docs/diagramas/README.md).
* **Visões contempladas:**
  * **Nível 1 (Contexto):** Usuário do Banco ↔ Meu Pix ↔ Simulador SPI/DICT (BACEN).
  * **Nível 2 (Containers):** Aplicação Web (Vue.js), Core Backend em Arquitetura Hexagonal (Node.js/Express), Message Broker (RabbitMQ), Serviço de Notificações (Node.js Worker) e Banco de Dados (PostgreSQL).
  * Nível 3 (Componentes) e Nível 4 (Código): próxima entrega (23/11–24/11).

Para visualizar o DSL localmente:

```bash
docker run -it --rm -p 8080:8080 -v "$PWD":/usr/local/structurizr structurizr/lite
```

## Documentação

* [Diagramas C4 (Contexto e Containers)](docs/diagramas/README.md)
* [Documento de Decisões Arquiteturais (ADRs)](docs/DECISOES-ARQUITETURAIS.md)

## Cronograma

| Data | Entrega | Status |
|---|---|---|
| 16/11 e 17/11 | Domínio, funcionalidades, estilo arquitetural, repositório e diagramas de Contexto e Container | ✅ |
| 23/11 e 24/11 | Diagramas de Componentes e Código | ⏳ |
| 01/12, 07/12 e 08/12 | Código rodando, conformidade com os diagramas e apresentação | ⏳ |

## Equipe
* Daniel Lucas Ulisses Magalhães - 554563
* Daniel Christopher de Souza - 552493
* Julian Cesar Pereira Cardoso - 553782
* Francisco Kauan Pereira Cavalcante - 554089
* Kleyton Kluesriton Ferreira Pereira - 555426
* Lucas Ferreira Nobre - 554590
