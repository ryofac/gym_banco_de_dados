-- Criar o papel para gerente com acesso completo
CREATE ROLE gerente;

-- Criar o papel para funcionário com acesso limitado
CREATE ROLE funcionario;

-- Criar o papel para instrutor com acesso limitado
CREATE ROLE instrutor;

-- Criar o papel do estagiario, para ter acesso aos treinos e as vendas realizadas
CREATE ROLE estagiario;

-- PERMISSOES gerente
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA PUBLIC TO gerente;

GRANT EXECUTE ON ALL functions IN SCHEMA PUBLIC TO gerente;

-- PERMISSOES FUNCIONARIO
GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON cliente TO funcionario;

GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON matricula TO funcionario;

GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON venda TO funcionario;

GRANT EXECUTE ON FUNCTION realizar_matricula (INT, INT, INT) TO funcionario;

GRANT EXECUTE ON FUNCTION iniciar_venda (INT, INT) TO funcionario;

GRANT EXECUTE ON FUNCTION confirmar_venda (INT) TO funcionario;

GRANT EXECUTE ON FUNCTION cancelar_venda (INT) TO funcionario;

GRANT EXECUTE ON FUNCTION registrar_produto_na_compra (INT, INT, INT) TO funcionario;

GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON informacoes_matriculas TO funcionario;

GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON informacoes_vendas TO funcionario;

-- Funções para o funcionário:
GRANT EXECUTE ON FUNCTION realizar_matricula (INT, INT, INT) TO funcionario;

GRANT EXECUTE ON FUNCTION iniciar_venda (INT, INT) TO funcionario;

GRANT EXECUTE ON FUNCTION confirmar_venda (INT) TO funcionario;

GRANT EXECUTE ON FUNCTION cancelar_venda (INT) TO funcionario;

GRANT EXECUTE ON FUNCTION registrar_produto_na_compra (INT, INT, INT) TO funcionario;

-- PERMISSOES INSTRUTOR
-- Conceder permissões de SELECT, INSERT, UPDATE nas tabelas de plano_treino e cliente para instrutor
GRANT
SELECT
,
  INSERT,
UPDATE ON cliente TO instrutor;

GRANT
SELECT
,
  INSERT,
UPDATE ON plano_treino TO instrutor;

-- Conceder permissões de execução apenas nas funções que manipulam plano de treino e cliente
GRANT EXECUTE ON FUNCTION criar_plano_de_treino (INT, INT, VARCHAR, VARCHAR) TO instrutor;

GRANT EXECUTE ON FUNCTION adicionar_exercicio_no_treino (INT, INT, INT, INT, INT) TO instrutor;

GRANT EXECUTE ON FUNCTION visualizar_plano_treino (INT) TO instrutor;

GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON informacoes_matriculas TO instrutor;

GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON informacoes_vendas TO instrutor;

-- PERMISSOES USUARIO
GRANT EXECUTE ON FUNCTION visualizar_plano_treino (INT) TO estagiario;

GRANT EXECUTE ON FUNCTION visualizar_vendas_do_cliente (INT) TO estagiario;

-- Dando permissão pra todo mundo acessar
GRANT usage ON SCHEMA PUBLIC TO gerente,
funcionario,
instrutor,
estagiario;

-- Criando de usuários:
-- Criando os usuários que serão atribuídos aos roles
CREATE USER usuario_gerente
WITH
  password 'senha123';

CREATE USER usuario_funcionario
WITH
  password 'senha123';

CREATE USER usuario_instrutor
WITH
  password 'senha123';

CREATE USER usuario_estagiario
WITH
  password 'senha123';

-- Atribuindo os roles:
GRANT gerente TO usuario_gerente;

GRANT funcionario TO usuario_funcionario;

GRANT instrutor TO usuario_instrutor;

GRANT estagiario TO usuario_estagiario