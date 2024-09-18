-- Criar o papel para gerente com acesso completo
CREATE ROLE gerente;

-- Criar o papel para funcionário com acesso limitado
CREATE ROLE funcionario;

-- Criar o papel para instrutor com acesso limitado
CREATE ROLE instrutor;

-- Criar o papel do cliente, para ter acesso aos treinos e as vendas realizadas
CREATE ROLE cliente;

-- PERMISSOES gerente
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gerente;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO gerente;

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

GRANT EXECUTE ON FUNCTION realizar_matricula (int, int, int) TO funcionario;

GRANT EXECUTE ON FUNCTION iniciar_venda (int, int) TO funcionario;

GRANT EXECUTE ON FUNCTION confirmar_venda (int) TO funcionario;

GRANT EXECUTE ON FUNCTION cancelar_venda (int) TO funcionario;

GRANT EXECUTE ON FUNCTION registrar_produto_na_compra (int, int, int) TO funcionario;

GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON INFORMACOES_MATRICULAS TO funcionario;

GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON INFORMACOES_VENDAS TO funcionario;

-- Funções para o funcionário:
GRANT EXECUTE ON FUNCTION realizar_matricula (int, int, int) TO funcionario;

GRANT EXECUTE ON FUNCTION iniciar_venda (int, int) TO funcionario;

GRANT EXECUTE ON FUNCTION confirmar_venda (int) TO funcionario;

GRANT EXECUTE ON FUNCTION cancelar_venda (int) TO funcionario;

GRANT EXECUTE ON FUNCTION registrar_produto_na_compra (int, int, int) TO funcionario;

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
GRANT EXECUTE ON FUNCTION criar_plano_de_treino (int, int, varchar, varchar) TO instrutor;

GRANT EXECUTE ON FUNCTION adicionar_exercicio_no_treino (int, int, int, int, int) TO instrutor;

GRANT EXECUTE ON FUNCTION visualizar_plano_treino (int) TO instrutor;

GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON INFORMACOES_MATRICULAS TO instrutor;

GRANT
SELECT
,
  INSERT,
UPDATE,
DELETE ON INFORMACOES_VENDAS TO instrutor;

-- PERMISSOES USUARIO
GRANT EXECUTE ON FUNCTION visualizar_plano_treino (int) TO cliente;

GRANT EXECUTE ON FUNCTION visualizar_vendas_do_cliente (int) TO cliente;

-- Dando permissão pra todo mundo acessar
GRANT USAGE ON SCHEMA public TO gerente,
funcionario,
instrutor,
cliente;