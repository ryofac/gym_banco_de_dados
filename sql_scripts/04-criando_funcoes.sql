----- FUNCOES GENERICAS ------
-- FUNÇÃO GENÉRICA DE INSERÇÃO DE DADOS
CREATE OR REPLACE FUNCTION INSERIR_DADOS(
    NOME_TABELA VARCHAR,
    CAMPOS TEXT,
    VALORES TEXT
) RETURNS VOID AS $$
BEGIN
    EXECUTE format('INSERT INTO %I (%s) VALUES (%s)', NOME_TABELA, CAMPOS, VALORES);
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao inserir dados: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
-- TODO: DELECAO GENERICA
-- TODO: ATUALIZACAO GENERICA

----- FUNCOES VENDA -----
-- TODO: BUSCAR ANTES SE O CLIENTE E O FUNCIONARIO EXISTEM
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
	RAISE INFO 'INSERINDO % PRODUTOS NA VENDA %S', quantidade, venda_id;
	
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION confirmar_venda(VENDA_ID INT)
RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (SELECT * FROM venda WHERE id_venda = VENDA_ID AND status = 'PENDENTE') THEN
    RAISE EXCEPTION 'Venda de id % não encontrada ou já confirmada/cancelada!', VENDA_ID;
  END IF;
  IF (SELECT QNT_PRODUTOS FROM VENDA WHERE ID_VENDA = VENDA_ID) <= 0 THEN
	RAISE EXCEPTION 'Venda de id % não possui produtos!', VENDA_ID;
  END IF;
  UPDATE VENDA SET STATUS='CONCLUIDA', dt_venda_final=NOW() WHERE ID_VENDA = VENDA_ID;
	
END;
$$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION cancelar_venda(venda_id int)
RETURNS VOID AS $$
DECLARE prod RECORD;
BEGIN
 IF NOT EXISTS (SELECT * FROM venda WHERE id_venda = venda_id AND status = 'PENDENTE') THEN
    RAISE EXCEPTION 'Venda de id % não encontrada ou já confirmada/cancelada!', VENDA_ID;
  END IF;

 UPDATE VENDA SET status='CANCELADO' WHERE ID_VENDA = VENDA_ID;

-- RETORNA A QUANTIDADE DE PRODUTOS DA VENDA QUE ESTAVA PENDENTE PARA O ESTOQUE
 FOR prod IN
	 SELECT iv.id_produto, iv.quantidade, p.nome, p.qnt_em_estoque
	    FROM item_venda iv
	    JOIN produto p ON iv.id_produto = p.id_produto
	    WHERE iv.id_venda = VENDA_ID
	 LOOP
		RAISE INFO 'Retornarndo % produtos (%) para o estoque!', prod.quantidade, prod.nome;
	    UPDATE produto
		SET qnt_em_estoque = prod.qnt_em_estoque + prod.quantidade
		WHERE id_produto = prod.id_produto;
	 END LOOP;	
END
$$
LANGUAGE PLPGSQL;

----- FUNCOES ACADEMIA -----

-- Função que realiza a matrícula de um cliente previamente registrado e atualiza caso ele já tenha se matriculado alguma vez
-- TODO: Adicionar esquema de multa caso a data da realização da matrícula seja maior que a data de vencimento 
CREATE OR REPLACE FUNCTION REALIZAR_MATRICULA(CLIENTE_ID INT, FUNCIONARIO_ID INT, PACOTE_ID INT)
RETURNS VOID AS $$
DECLARE pacote RECORD;
DECLARE nome_cliente varchar;
BEGIN
	-- Validação de existencia dos ids
	IF NOT EXISTS(SELECT * FROM CLIENTE C WHERE C.ID_CLIENTE = CLIENTE_ID) THEN
			RAISE EXCEPTION 'Cliente de id % não encontrado!', VENDA_ID;
		END IF;

	IF NOT EXISTS(SELECT * FROM FUNCIONARIO F WHERE F.ID_FUNCIONARIO = FUNCIONARIO_ID) THEN
		RAISE EXCEPTION 'Funcionário de id % não encontrado!', FUNCIONARIO_ID;
	END IF;
	
	IF NOT EXISTS(SELECT * FROM PACOTE P WHERE P.ID_PACOTE = PACOTE_ID) THEN
		RAISE EXCEPTION 'Pacote de id % não encontrado!', PACOTE_ID;
	END IF;

	-- Populando as variáveis declaradas
	SELECT nome into nome_cliente FROM CLIENTE WHERE id_cliente = cliente_id;
	SELECT * INTO pacote from pacote where id_pacote = PACOTE_ID;

	-- Verificando se já existe algum registro vinculado aquele cliente, se sim, atualiza ele
	IF EXISTS (SELECT * FROM MATRICULA WHERE ID_CLIENTE = CLIENTE_ID) THEN
		RAISE INFO 'Matrícula do cliente %s renovada', nome_cliente;
		UPDATE MATRICULA SET DT_PAGAMENTO=NOW(), DT_VENCIMENTO=DT_PAGAMENTO + INTERVAL '1 day' * pacote.duracao_dias WHERE ID_CLIENTE = CLIENTE_ID;
		RETURN;
	END IF;
	
	-- Registrando uma nova matrícula
	RAISE INFO 'Matrícula do cliente %s registrada', nome_cliente;
	INSERT INTO MATRICULA(id_cliente, id_funcionario, id_pacote, valor_pago, dt_pagamento, dt_vencimento) VALUES (CLIENTE_ID, FUNCIONARIO_ID, PACOTE_ID, pacote.valor, NOW(), NOW() + INTERVAL '1 day' * pacote.duracao_dias);
END;
$$ LANGUAGE PLPGSQL;
