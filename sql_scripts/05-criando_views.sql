-- Atalho para obter as informações relativas as vendas
-- Na prática faz um join nas tabelas envolvidas
CREATE VIEW
  INFORMACOES_VENDAS AS
SELECT
  v.id_venda,
  c.nome nome_cliente,
  f.nome nome_funcionario,
  v.qnt_produtos,
  v.valor_total,
  v.dt_venda,
  v.dt_venda_final,
  v.status
FROM
  cliente c
  NATURAL LEFT JOIN VENDA V
  JOIN funcionario f ON f.id_funcionario = v.id_funcionario;

-- Atalho para obter informações relativas as matrículas do momento
CREATE VIEW
  INFORMACOES_MATRICULAS AS
SELECT
  m.id_matricula,
  C.nome nome_cliente,
  f.nome nome_funcionario,
  p.nome nome_pacote,
  duracao_dias,
  p.valor valor_pago,
  dt_pagamento data_ultimo_pagamento,
  dt_vencimento
FROM
  matricula M
  JOIN cliente C ON M.id_cliente = C.id_cliente
  JOIN funcionario f ON F.id_funcionario = M.id_funcionario
  JOIN PACOTE P ON P.id_pacote = M.id_pacote;