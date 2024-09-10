-- Atalho para obter as informações relativas as vendas
-- Na prática faz um join nas tabelas envolvidas
CREATE VIEW
  INFORMACOES_MATRICULAS AS
SELECT
  m.id_matricula,
  C.nome nome_cliente,
  f.nome nome_funcionario,
  p.nome nome_pacote,
  duracao_dias,
  m.valor_pago valor_pago,
  dt_pagamento data_ultimo_pagamento,
  dt_vencimento
FROM
  matricula M
  JOIN cliente C ON M.id_cliente = C.id_cliente
  JOIN funcionario f ON F.id_funcionario = M.id_funcionario
  JOIN PACOTE P ON P.id_pacote = M.id_pacote;