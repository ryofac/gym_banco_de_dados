CREATE VIEW
  INFORMACOES_VENDAS AS
SELECT
  v.id_venda,
  c.nome nome_cliente,
  f.nome nome_funcionario,
  v.qnt_produtos,
  v.valor_total,
  v.dt_venda,
  v.status
FROM
  cliente c
  NATURAL LEFT JOIN VENDA V
  JOIN funcionario f ON f.id_funcionario = v.id_funcionario;