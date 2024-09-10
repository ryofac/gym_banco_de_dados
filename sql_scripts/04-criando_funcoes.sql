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

-- -- Funcao que verifica a existencia de um dado
-- CREATE OR REPLACE FUNCTION verificar_existencia_tabela(
--     tabela_nome TEXT,    
--     pk_coluna TEXT,      
--     pk_valor INT 
-- )
-- RETURNS VOID AS $$
-- DECLARE
--     query TEXT;
-- BEGIN
--     query := format(
--         'SELECT 1 FROM %I WHERE %I = $1',
--         tabela_nome,  -- Nome da tabela
--         pk_coluna     -- Nome da coluna da chave primária
--     );

--     IF NOT EXISTS (EXECUTE query USING pk_valor) THEN
--         RAISE EXCEPTION 'Registro com % = % não encontrado na tabela %!',
--             pk_coluna, pk_valor, tabela_nome;
--     END IF;
-- END;
-- $$ LANGUAGE plpgsql;

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
-- Realiza a matricula de um cliente, dado o id e o funcionario e o pacote
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
	
	-- Registrando uma nova matrícula
	INSERT INTO MATRICULA(id_cliente, id_funcionario, id_pacote, valor_pago, dt_pagamento, dt_vencimento) VALUES 
	(CLIENTE_ID, FUNCIONARIO_ID, PACOTE_ID, pacote.valor, NOW(), NOW() + INTERVAL '1 day' * pacote.duracao_dias);
	RAISE INFO 'Matrícula do cliente %s recebida!', nome_cliente;
END;
$$ LANGUAGE PLPGSQL;

-- Cria um plano de treino, dado o instrutor, o cliente, o objetivo e notas
CREATE OR REPLACE FUNCTION CRIAR_PLANO_DE_TREINO(CLIENTE_ID INT, INSTRUTOR_ID INT, objetivo VARCHAR, notas VARCHAR)
RETURNS VOID AS $$
DECLARE cliente_existente RECORD;
DECLARE id_novo_plano int;
BEGIN
	SELECT * INTO cliente_existente from CLIENTE C WHERE C.ID_CLIENTE = CLIENTE_ID;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'Cliente de id % não existe!', CLIENTE_ID;
	END IF;
	
	IF cliente_existente.id_plano IS NOT NULL THEN
		RAISE EXCEPTION 'Cliente de id % já possui um plano de treino assossiado! Exclua-o primeiro', CLIENTE_ID;
	END IF;

	IF NOT EXISTS(SELECT * FROM instrutor i  WHERE i.id_instrutor = INSTRUTOR_ID) THEN
			RAISE EXCEPTION 'Instrutor de id % não encontrado!', INSTRUTOR_ID;
	END IF;
	
	INSERT INTO plano_treino VALUES (DEFAULT, INSTRUTOR_ID, objetivo, notas) RETURNING id_plano into id_novo_plano;
	UPDATE CLIENTE SET ID_PLANO = id_novo_plano WHERE ID_CLIENTE = CLIENTE_ID;

END;
$$ LANGUAGE plpgsql;
