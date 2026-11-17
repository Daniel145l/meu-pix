# Meu Pix - Sistema Bancário e PIX

Repositório oficial do projeto final da disciplina de **Arquitetura de Software**, desenvolvido com foco no domínio de **Sistema Bancário e PIX**.

## Sobre o Projeto

O **Meu Pix** é uma aplicação de simulação de carteira digital e pagamentos instantâneos. O sistema foi projetado para permitir que usuários gerenciem suas contas, realizem consultas de saldo, cadastrem e gerenciem chaves PIX, além de efetuar transferências instantâneas de forma segura, rápida e desacoplada.

## Estilo Arquitetural: Arquitetura Hexagonal (Ports and Adapters)

O projeto adota **majoritariamente os princípios da Arquitetura Hexagonal**.

* **Por que essa escolha?** O núcleo de negócio (domínio PIX, regras de transferência e validações de saldo) fica completamente isolado de detalhes tecnológicos externos (como frameworks web, bancos de dados ou integrações de APIs de terceiros).

* **Vantagens:** Facilidade para criar testes automatizados, flexibilidade para alterar adaptadores de entrada (REST APIs) e de saída (Persistence/SPI do BACEN) sem impactar as regras centrais da aplicação.

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

Seguindo as exigências do trabalho, a arquitetura do sistema está documentada utilizando o **Modelo C4 através de código com Structurizr DSL**.

* O arquivo de configuração do modelo encontra-se na raiz do repositório como `workspace.dsl`.
* **Visões contempladas:**
  * **Nível 1 (Contexto):** Interação do usuário e o sistema Meu Pix com o simulador externo do SPI/BACEN.
  * **Nível 2 (Containers):** Separação clara entre a Aplicação Web (Frontend), a Core API (Backend em Arquitetura Hexagonal), o Banco de Dados Relacional e o Serviço de Notificações.
## Equipe
* Daniel Lucas Ulisses Magalhães - 554563
* Daniel Christopher de Souza - 552493
* Julian Cesar Pereira Cardoso - 553782
* Francisco Kauan Pereira Cavalcante - 554089
* Kleyton Kluesriton Ferreira Pereira - 555426
* Lucas Ferreira Nobre - 554590
* 

* A divisão de tarefas e o progresso do desenvolvimento podem ser acompanhados diretamente através das abas de *Issues* e *Projects* deste repositório no GitHub.
