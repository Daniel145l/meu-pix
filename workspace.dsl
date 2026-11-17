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
            }

            coreBackend = container "Core Backend" "Núcleo de negócio em Arquitetura Hexagonal: expõe a API REST (adaptador de entrada) e executa as regras de contas, chaves e transferências PIX. Fala com o mundo externo apenas por portas de saída (repositórios, gateway SPI e publicador de eventos)." "Node.js / Express / TypeScript" {
                tags "Hexagonal"
            }

            broker = container "Message Broker" "Fila/tópico de eventos de domínio (ex.: PixEnviado, PixRecebido, ChavePixCadastrada). Desacopla quem produz o evento de quem reage a ele." "RabbitMQ" {
                tags "Fila"
            }

            notificationWorker = container "Serviço de Notificações" "Consumidor assíncrono dos eventos de domínio: gera comprovantes e notificações de operações concluídas e as registra para o usuário." "Node.js Worker / TypeScript"

            database = container "Banco de Dados" "Armazena usuários, contas, saldos, chaves PIX, transações (extrato) e notificações." "PostgreSQL (Supabase)" {
                tags "Banco de Dados"
            }
        }

        # ---------------------------------------------------------------
        # Relações — nível de Contexto (derivadas/implícitas dos containers)
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
        meuPix.notificationWorker -> usuario "Envia notificação de operação concluída" "In-app / E-mail (simulado)"
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
