CREATE OR REPLACE FUNCTION decrementar_item_comprado()
RETURNS TRIGGER AS $$
DECLARE QNT_TOTAL_PRODUTO INT;
BEGIN
	SELECT qnt_em_estoque INTO QNT_TOTAL_PRODUTO from produto
	WHERE ID_PRODUTO = NEW.ID_PRODUTO;
	RAISE INFO 'TA INDO: %', QNT_TOTAL_PRODUTO;

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

CREATE OR REPLACE TRIGGER TRG_DECREMENTAR_ESTOQUE
AFTER INSERT ON ITEM_VENDA
FOR EACH ROW
EXECUTE FUNCTION decrementar_item_comprado();


CREATE FUNCTION ATUALIZAR_INFORMACOES_DA_VENDA()
RETURNS TRIGGER AS $$
BEGIN
	-- TODO: fazer um trigger que atualiza as informações da venda na tabela VENDA
  -- de acordo com as informações da tabela ITEM_VENDA
	
END;
$$
LANGUAGE PLPGSQL;


CREATE TRIGGER TRG_ATUALIZAR_INFORMACOES_DA_VENDA
AFTER INSERT ON ITEM_VENDA
EXECUTE FUNCTION ATUALIZAR_INFORMACOES_DA_VENDA()