workspace "Meu Pix - Sistema Bancário e PIX" "Documentação arquitetural (Modelo C4) do projeto final de Arquitetura de Software." {

    !identifiers hierarchical

    model {
        # ---------------------------------------------------------------
        # Pessoas
        # ---------------------------------------------------------------
        usuario = person "Usuário do Banco" "Correntista que consulta saldo e extrato, gerencia chaves PIX, realiza transferências e recebe notificações das operações concluídas."

        # ---------------------------------------------------------------
        # Sistemas externos
        # ---------------------------------------------------------------
        spi = softwareSystem "Simulador SPI / DICT (BACEN)" "Sistema externo simulado: o DICT resolve chaves PIX de outras instituições e o SPI liquida ordens PIX interbancárias." {
            tags "Sistema Externo"
        }

        # ---------------------------------------------------------------
        # Sistema em foco
        # ---------------------------------------------------------------
        meuPix = softwareSystem "Meu Pix" "Carteira digital que simula contas bancárias, chaves PIX e transferências instantâneas." {

            webapp = container "Aplicação Web" "Interface (SPA) para consultar saldo e extrato, gerenciar chaves PIX, enviar PIX e visualizar notificações." "Vue.js / TypeScript" {
                tags "Web Browser"

                dashboardView = component "Tela de Saldo e Extrato" "Exibe saldo atual, extrato e notificações recentes" "Vue Component / View"
                pixTransferView = component "Tela de Transferência e Chaves PIX" "Formulários para gerenciar chaves PIX e iniciar transferências" "Vue Component / View"
                httpClient = component "Cliente API REST" "Centraliza chamadas HTTP/JSON para o Core Backend" "Axios / Fetch Service"

                dashboardView -> httpClient "Busca saldo, extrato e notificações"
                pixTransferView -> httpClient "Envia PIX e gerencia chaves"
            }

            coreBackend = container "Core Backend" "Núcleo de negócio em Arquitetura Hexagonal: expõe a API REST (adaptador de entrada) e executa as regras de contas, chaves e transferências PIX. Fala com o mundo externo apenas por portas de saída (repositórios, gateway SPI e publicador de eventos)." "Node.js / Express / TypeScript" {
                tags "Hexagonal"

                # Adapters de Entrada (Driving)
                accountController = component "Account Controller" "Recebe requisições de consulta de saldo e extrato" "REST Controller"
                transferController = component "Transfer Controller" "Recebe solicitações de iniciação de transferência PIX" "REST Controller"

                # Casos de Uso / Domínio
                accountUseCase = component "Account & Balance Use Case" "Consulta saldo e histórico de movimentações" "Application Service"
                transferPixUseCase = component "Transfer PIX Use Case" "Valida saldo, realiza débito/crédito, liquida e publica eventos" "Domain / Application Service"

                # Portas (Interfaces)
                accountRepoPort = component "Account Repository Port" "Contrato para persistência de contas e saldos" "Port"
                bacenSpiPort = component "BACEN SPI / DICT Port" "Contrato para consulta de chave e liquidação no SPI" "Port"
                eventPublisherPort = component "Domain Event Publisher Port" "Contrato para publicação de eventos de domínio" "Port"

                # Adapters de Saída (Driven)
                pgAccountAdapter = component "PostgreSQL Account Adapter" "Executa operações de contas e transações no banco" "Outbound Adapter"
                spiDictAdapter = component "SPI / DICT Adapter" "Integra com o simulador externo do SPI / DICT" "Outbound Adapter"
                brokerPublisherAdapter = component "Message Broker Adapter" "Publica eventos de domínio no broker" "Outbound Adapter"

                # Fluxos internos — Consulta de Saldo e Extrato
                accountController -> accountUseCase "Consulta saldo e extrato"
                accountUseCase -> accountRepoPort "Solicita dados da conta"
                accountRepoPort -> pgAccountAdapter "Implementado por"

                # Fluxos internos — Transferência PIX
                transferController -> transferPixUseCase "Inicia transferência PIX"
                transferPixUseCase -> accountRepoPort "Valida saldo e registra débito/crédito"
                transferPixUseCase -> bacenSpiPort "Consulta DICT e envia ordem SPI"
                bacenSpiPort -> spiDictAdapter "Implementado por"
                transferPixUseCase -> eventPublisherPort "Publica evento de transferência"
                eventPublisherPort -> brokerPublisherAdapter "Implementado por"
            }

            broker = container "Message Broker" "Fila/tópico de eventos de domínio (ex.: PixEnviado, PixRecebido, ChavePixCadastrada). Desacopla quem produz o evento de quem reage a ele." "RabbitMQ" {
                tags "Fila"
            }

            notificationWorker = container "Serviço de Notificações" "Consumidor assíncrono dos eventos de domínio: gera comprovantes e notificações de operações concluídas e as registra para o usuário." "Node.js Worker / TypeScript" {

                eventConsumer = component "Consumidor de Eventos PIX" "Escuta eventos PixEnviado / PixRecebido no broker" "AMQP Consumer"
                receiptGenerator = component "Gerador de Comprovante e Alerta" "Monta o comprovante e a mensagem de operação concluída" "Domain / Application Service"
                notificationRepo = component "Repositório de Notificações" "Persiste notificações e comprovantes no banco" "Repository / Adapter"
                notifierSender = component "Emissor de Notificação" "Despacha alerta in-app / e-mail simulado ao usuário" "Notifier Adapter"

                eventConsumer -> receiptGenerator "Encaminha payload do evento"
                receiptGenerator -> notificationRepo "Salva comprovante e notificação"
                receiptGenerator -> notifierSender "Dispara entrega ao usuário"
            }

            database = container "Banco de Dados" "Armazena usuários, contas, saldos, chaves PIX, transações (extrato) e notificações." "PostgreSQL (Supabase)" {
                tags "Banco de Dados"
            }
        }

        # ---------------------------------------------------------------
        # Relações de Componente — Aplicação Web e Serviço de Notificações
        # ---------------------------------------------------------------
        usuario -> meuPix.webapp.dashboardView "Consulta saldo, extrato e notificações" "HTTPS"
        usuario -> meuPix.webapp.pixTransferView "Gerencia chaves e envia PIX" "HTTPS"
        meuPix.webapp.httpClient -> meuPix.coreBackend "Envia requisições REST/JSON" "JSON / HTTPS"

        meuPix.broker -> meuPix.notificationWorker.eventConsumer "Entrega eventos PixEnviado / PixRecebido" "AMQP"
        meuPix.notificationWorker.notificationRepo -> meuPix.database "Grava notificações e comprovantes" "SQL / TCP"
        meuPix.notificationWorker.notifierSender -> usuario "Envia notificação de operação concluída" "In-app / E-mail (simulado)"

        # ---------------------------------------------------------------
        # Relações — nível de Componente (integrações com containers/sistemas)
        # ---------------------------------------------------------------
        meuPix.webapp -> meuPix.coreBackend.accountController "Consulta saldo e extrato" "JSON / HTTPS (REST)"
        meuPix.webapp -> meuPix.coreBackend.transferController "Solicita transferência PIX" "JSON / HTTPS (REST)"
        meuPix.coreBackend.pgAccountAdapter -> meuPix.database "Lê e grava contas e transações" "SQL / TCP"
        meuPix.coreBackend.spiDictAdapter -> spi "Consulta chave no DICT e envia ordem ao SPI" "JSON / HTTPS"
        meuPix.coreBackend.brokerPublisherAdapter -> meuPix.broker "Publica eventos de domínio" "AMQP"

        # ---------------------------------------------------------------
        # Relações — nível de Contexto
        # ---------------------------------------------------------------
        usuario -> meuPix "Consulta saldo/extrato, gerencia chaves PIX e envia PIX"
        meuPix -> usuario "Notifica operações concluídas"
        meuPix -> spi "Resolve chaves de outras instituições e envia ordens PIX interbancárias"

        # ---------------------------------------------------------------
        # Relações — nível de Container
        # ---------------------------------------------------------------
        usuario -> meuPix.webapp "Acessa pelo navegador" "HTTPS"
        meuPix.webapp -> meuPix.coreBackend "Faz chamadas à API (saldo, extrato, chaves, PIX, notificações)" "JSON / HTTPS (REST)"
        meuPix.coreBackend -> meuPix.database "Lê e grava contas, chaves PIX e transações (débito e crédito na mesma transação)" "SQL / TCP"
        meuPix.coreBackend -> meuPix.broker "Publica eventos de domínio após concluir a operação" "AMQP (assíncrono)"
        meuPix.coreBackend -> spi "Consulta chave no DICT e envia ordem de pagamento ao SPI" "JSON / HTTPS (síncrono)"
        meuPix.notificationWorker -> meuPix.broker "Consome eventos PixEnviado / PixRecebido" "AMQP (assíncrono)"
        meuPix.notificationWorker -> meuPix.database "Registra notificações e comprovantes" "SQL / TCP"
    }

    views {
        systemContext meuPix "Contexto" "Nível 1 (C4) — o Meu Pix, quem o usa e com quais sistemas externos ele se comunica." {
            include *
            autoLayout lr
        }

        container meuPix "Containers" "Nível 2 (C4) — unidades executáveis/implantáveis do Meu Pix, suas tecnologias e mecanismos de comunicação." {
            include *
            autoLayout lr
        }

        component meuPix.coreBackend "Componentes_Core_Backend" "Nível 3 (C4) — componentes internos do Core Backend em Arquitetura Hexagonal." {
            include *
            autoLayout lr
        }

        component meuPix.webapp "Componentes_Aplicacao_Web" "Nível 3 (C4) — componentes da interface SPA em Vue.js / TypeScript." {
            include *
            autoLayout lr
        }

        component meuPix.notificationWorker "Componentes_Servico_Notificacoes" "Nível 3 (C4) — componentes do worker assíncrono de notificações." {
            include *
            autoLayout lr
        }

        styles {
            element "Element" {
                color #ffffff
            }
            element "Person" {
                background #08427b
                shape Person
            }
            element "Software System" {
                background #1168bd
            }
            element "Sistema Externo" {
                background #999999
            }
            element "Container" {
                background #438dd5
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "Hexagonal" {
                shape Hexagon
            }
            element "Fila" {
                shape Pipe
            }
            element "Banco de Dados" {
                shape Cylinder
            }
        }
    }
}
