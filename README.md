## Configuração do Ambiente com Docker Compose

### 1. Configuração Inicial

- **Criar o Arquivo `.env`**:
  - Baseie-se no arquivo `dot-env-example` para criar o seu arquivo `.env`.
  - Este arquivo deve conter todas as variáveis de ambiente necessárias para a configuração do seu banco de dados.

### 2. Comandos Docker

- **Subir o Banco de Dados e Executar Scripts**:

  - Para iniciar o banco de dados e executar os scripts SQL, execute:
    ```bash
    docker-compose up
    ```
  - Isso iniciará os containers definidos no `docker-compose.yml` e aplicará os scripts localizados na pasta `sql-scripts`.

- **Parar e Remover o Banco de Dados**:
  - Para parar os containers e remover volumes associados (o que apaga o banco de dados), use:
    ```bash
    docker-compose down -v
    ```

## Estrutura do Projeto

- **`docker-compose.yml`**: Arquivo de configuração do Docker Compose que define os serviços, volumes e redes.
- **`dot-env-example`**: Exemplo de arquivo de variáveis de ambiente. Renomeie para `.env` e ajuste conforme necessário.
- **`sql-scripts/`**: Diretório contendo os scripts SQL a serem executados no banco de dados automaticamente assim que o container subir.

## TODO

### Core:

- [x] Adicionar esquema de inserir exercícios em um plano de treino
- [x] Funções de atualizar e deletar genéricas
- [x] Adicionar desconto nos produtos, caso o cliente esteja com a matrícula ativa na academia
- [x] Conferir se o cliente e funcionário existem ao realizar a venda
- [ ] Funções de relatório (Obter lucro com matrículas entre X e Y, quantos clientes novos cadastrados, quantas vendas realizadas, etc.)
- [x] Controle de permissões (Criar usuários, grupos e roles interagindo com views)
- [x] Adicionar dias da semana junto ao plano de treino
- [ ] Adicionar meio de remover ou alterar itens de uma venda

### Melhorias

- [x] Sistema de auditoria
- [x] Não vender para clientes que estão com a mensalidade atrasada
- [ ] Adicionar clientes inativos (ou seja, quando atrasarem a matrícula, não podem ter planos de treino)
- [ ] Normalizar o atributo status da venda (tabela separada, levando o id)
