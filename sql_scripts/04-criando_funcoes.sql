CREATE OR REPLACE FUNCTION INICIAR_VENDA(ID_CLIENTE INT, ID_FUNCIONARIO INT)
RETURNS VOID AS $$
BEGIN 
	INSERT INTO VENDA VALUES(DEFAULT, ID_CLIENTE, ID_FUNCIONARIO, 0, 0, NOW());
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION registrar_produto_na_compra(VENDA_ID INT, PRODUTO_ID INT , QUANTIDADE INT)
RETURNS VOID AS $$
BEGIN 
	IF NOT EXISTS(SELECT * FROM VENDA V WHERE V.ID_VENDA = VENDA_ID) THEN
		RAISE EXCEPTION 'Venda de id % não encontrada!', VENDA_ID;
	END IF;

	IF NOT EXISTS(SELECT * FROM PRODUTO P WHERE P.ID_PRODUTO = PRODUTO_ID) THEN
		RAISE EXCEPTION 'Produto de id % não encontrado!', PRODUTO_ID;
	END IF;
	
	INSERT INTO ITEM_VENDA (id_produto, id_venda, quantidade) VALUES (PRODUTO_ID, VENDA_ID, QUANTIDADE);
	
END;
$$
LANGUAGE PLPGSQL;