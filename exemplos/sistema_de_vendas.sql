-- REALIZANDO UMA COMPRA --
-- INICIANDO VENDA COM O CLIENTE 1 E O FUNCIONARIO 2
SELECT
  INICIAR_VENDA (1, 2);

-- TENTANDO CONFIRMAR VENDA MAS NEGANDO
-- MOTIVO: NENHUM PRODUTO RELACIONADO
SELECT
  CONFIRMAR_VENDA (1);

-- REGISTRANDO 1 WHEY PROTEIN NA COMPRA 1
SELECT
  REGISTRAR_PRODUTO_NA_COMPRA (1, 1, 1);

-- CONFIRMANDO A COMPRA 1 (ADICIONANDO DATA FINAL E MUDANDO O STATUS)
SELECT
  CONFIRMAR_VENDA (1);

-- REALIZANDO UM CANCELAMENTO
-- INICIANDO VENDA COM O CLIENTE 1 E O FUNCIONARIO 2
SELECT
  INICIAR_VENDA (1, 2);

-- CANCELANDO VENDA 2
SELECT
  CANCELAR_VENDA (2);


-- ALTERANDO PRODUTOS DE UMA COMPRA:
-- INICIANDO VENDA COM O CLIENTE 1 E O FUNCIONARIO 2
SELECT
  INICIAR_VENDA (1, 2);

-- REGISTRANDO 10 WHEY PROTEIN NA COMPRA ID 3
SELECT
  REGISTRAR_PRODUTO_NA_COMPRA (
    (SELECT OBTER_ID_DA_ULTIMA_VENDA_PENDENTE()), 1, 10);

-- REGISTRANDO 5 CAMISETA ESPORTIVA NA COMPRA ID 3
SELECT
  REGISTRAR_PRODUTO_NA_COMPRA (3, 2, 5);

-- REMOVENDO 2 CAMISETA ESPORTIVA DA COMPRA ID 3
SELECT
  REMOVER_PRODUTO_DA_COMPRA (3, 2, 2);

-- CONFIRMANDO A COMPRA 3
SELECT
  CONFIRMAR_VENDA (3);

-- VISUALIZANDO AS VENDAS REALIZADAS EM 2024:
SELECT * FROM RELATORIO_VENDAS ('2024-01-01', '2024-12-31');

-- VIEW PARA VISUALIZAR MELHOR AS VENDAS:
SELECT
  *
FROM
  INFORMACOES_VENDAS
ORDER BY
  ID_VENDA;