workspace "PixFlow - Sistema Bancário e PIX" {

    model {
        user = person "Usuário do Banco" "Realiza consultas de saldo, gerencia chaves PIX e faz transferências."
        
        system = softwareSystem "PixFlow System" "Sistema de simulação bancária e pagamentos via PIX." {
            webapp = container "Aplicação Web / Frontend" "Interface de usuário para interagir com o sistema." "Vue.js / TypeScript"
            apiGateway = container "Core Backend (Arquitetura Hexagonal)" "Gerencia rotas, adaptadores de entrada e as regras de negócio de contas e PIX." "Node.js / Express / TypeScript"
            database = container "Banco de Dados Relacional" "Armazena dados de usuários, contas, saldos e chaves PIX." "PostgreSQL / Supabase"
            notificationService = container "Serviço de Notificações" "Envia alertas e comprovantes de operações concluídas." "Node.js Worker"
        }
        
        externalBacen = softwareSystem "Simulador do SPI / BACEN" "Sistema externo simulado para liquidação de ordens PIX interbancárias."

        # Relações de Contexto
        user -> system "Usa para gerenciar dinheiro e enviar PIX"
        system -> externalBacen "Liquida transações PIX"

        # Relações de Container
        user -> webapp "Acessa via navegador"
        webapp -> apiGateway "Faz requisições HTTPS/REST"
        apiGateway -> database "Lê e grava dados de contas e transações"
        apiGateway -> notificationService "Dispara eventos de transferência"
        apiGateway -> externalBacen "Consulta e envia ordens PIX"
    }

    views {
        systemContext system "Contexto" {
            include *
            autoLayout
        }
        
        container system "Containers" {
            include *
            autoLayout
        }
        
        styles {
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}