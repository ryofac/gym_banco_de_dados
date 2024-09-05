CREATE VIEW INFORMACOES_VENDAS AS SELECT 
c.nome nome_cliente, 
f.nome nome_funcionario, 
v.qnt_produtos, v.valor_total,
v.dt_venda 
FROM cliente c 
NATURAL LEFT JOIN VENDA V JOIN funcionario f 
ON f.id_funcionario = v.id_funcionario;