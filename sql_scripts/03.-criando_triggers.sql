----- TRIGGERS ITEM_VENDA ------
-- Trigger que decrementa a quantidade de um produto na tabela PRODUTO conforme for inserido em ITEM_VENDA
CREATE OR REPLACE FUNCTION decrementar_item_comprado()
RETURNS TRIGGER AS $$
DECLARE QNT_TOTAL_PRODUTO INT;
BEGIN
	SELECT qnt_em_estoque INTO QNT_TOTAL_PRODUTO from produto
	WHERE ID_PRODUTO = NEW.ID_PRODUTO;

  IF (QNT_TOTAL_PRODUTO < 10) 
  THEN RAISE INFO 'Produto de id % está acabando! % restantes', NEW.ID_PRODUTO, QNT_TOTAL_PRODUTO;
  END IF;

	IF (QNT_TOTAL_PRODUTO < NEW.QUANTIDADE) THEN
		RAISE EXCEPTION 'Quantidade em estoque (%) insuficiente', QNT_TOTAL_PRODUTO;
	END IF;

	UPDATE PRODUTO 
	SET qnt_em_estoque = qnt_em_estoque - NEW.QUANTIDADE
	WHERE id_produto = NEW.id_produto;
	RETURN NEW;

END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_DECREMENTAR_ESTOQUE
AFTER INSERT ON ITEM_VENDA
FOR EACH ROW
EXECUTE FUNCTION decrementar_item_comprado();

-- Trigger que atualiza informações de uma venda quando uma linha for inserida na tabela ITEM_VENDA
CREATE OR REPLACE FUNCTION ATUALIZAR_INFORMACOES_DA_VENDA()
RETURNS TRIGGER AS $$
BEGIN	
	UPDATE venda
  SET qnt_produtos = qnt_produtos + NEW.quantidade,
      valor_total = valor_total + (SELECT valor_unitario FROM produto WHERE id_produto = NEW.id_produto) * NEW.quantidade
  WHERE id_venda = NEW.id_venda;
	RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER TRG_ATUALIZAR_INFORMACOES_DA_VENDA
AFTER INSERT ON ITEM_VENDA
FOR EACH ROW 
EXECUTE FUNCTION ATUALIZAR_INFORMACOES_DA_VENDA();

CREATE OR REPLACE FUNCTION PREVENIR_ALTERACAO_COMPRA_FINALIZADA_CANCELADA()
RETURNS TRIGGER AS $$
BEGIN 
  IF (SELECT status FROM venda WHERE id_venda = NEW.id_venda) IN ('CONCLUIDA', 'CANCELADA') THEN
    RAISE EXCEPTION 'Não é possível alterar itens em uma venda já confirmada ou cancelada!';
  END IF;
 	RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_PREVENIR_ALTERACAO_COMPRA_FINALIZADA_CANCELADA
BEFORE INSERT OR UPDATE ON item_venda
FOR EACH ROW
EXECUTE FUNCTION PREVENIR_ALTERACAO_COMPRA_FINALIZADA_CANCELADA();

---- SISTEMA DE ACADEMIA ----

---- UTILS ----
CREATE OR REPLACE FUNCTION OBTER_ULTIMA_MATRICULA_DO_CLIENTE(CLIENTE_ID INT)
RETURNS TABLE (id_matricula INT, id_cliente INT, dt_vencimento DATE, valor NUMERIC) AS $$
BEGIN

	RETURN QUERY
	SELECT M.id_matricula, M.id_cliente, M.dt_vencimento, M.valor_pago FROM MATRICULA M 
	WHERE M.ID_CLIENTE = CLIENTE_ID ORDER BY dt_vencimento desc limit 1; 
	
END;
$$ LANGUAGE PLPGSQL;




---- CORE ----
CREATE OR REPLACE FUNCTION RENOVAR_MATRICULA()
RETURNS TRIGGER AS $$
DECLARE ultima_matricula RECORD;
DECLARE data_referencia DATE;
DECLARE pacote RECORD;
DECLARE nome_cliente varchar;
BEGIN
	-- Populando variáveis declaradas
	SELECT * INTO ultima_matricula FROM MATRICULA M WHERE M.ID_CLIENTE = NEW.ID_CLIENTE ORDER BY dt_vencimento desc limit 1;
	SELECT * INTO pacote from pacote where id_pacote = NEW.ID_PACOTE;
	SELECT nome into nome_cliente FROM CLIENTE WHERE id_cliente = NEW.ID_CLIENTE;

	-- Verificando se o usuário possui já possui uma matrícula registrada 
	IF NOT ultima_matricula is NULL THEN
		data_referencia := ultima_matricula.dt_vencimento;
		-- Matricula vencida, usando a data padrão 
		IF ultima_matricula.dt_vencimento < NEW.dt_pagamento THEN
			data_referencia := NEW.dt_pagamento;
		END IF;
		RAISE INFO 'Matrícula do cliente %s renovada!', nome_cliente;
	ELSE data_referencia := NEW.dt_pagamento;
	END IF;

	NEW.dt_vencimento = data_referencia + INTERVAL '1 day' * pacote.duracao_dias; 
	
	RETURN NEW;
	
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_RENOVAR_MATRICULA
BEFORE INSERT ON MATRICULA
FOR EACH ROW 
EXECUTE FUNCTION RENOVAR_MATRICULA();


-- Aplica uma multa para uma matrícula, caso ela não tenha sido renovada dentro do prazo:
-- CREATE OR REPLACE FUNCTION aplicar_multa()
-- RETURNS TRIGGER AS $$
-- DECLARE
--     dias_atraso INT;
--     valor_multa DECIMAL;
-- 		ultimo
-- BEGIN
-- 		-- pegar o ultimo registro do cara na tabela
-- 		-- verificar a data de vencimento, se for menor que hoje, aplica multa

--     -- Verificar se a data de pagamento é posterior à data de vencimento
--     IF THEN
--         -- Calcular o número de dias de atraso
--         dias_atraso := NEW.dt_pagamento - NEW.dt_vencimento;

--         -- Definir o valor da multa (Exemplo: 2% do valor total por dia de atraso)
--         valor_multa := (NEW.valor_pago * 0.02 * dias_atraso);

--         -- Atualizar o valor pago com a multa
--         NEW.valor_pago := NEW.valor_pago + valor_multa;

--         RAISE NOTICE 'Multa aplicada: R$%, por % dias de atraso.', valor_multa, dias_atraso;
--     END IF;

--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trg_aplicar_multa
-- BEFORE INSERT OR UPDATE ON matricula
-- FOR EACH ROW
-- EXECUTE FUNCTION aplicar_multa();