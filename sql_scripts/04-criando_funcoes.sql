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


CREATE OR REPLACE FUNCTION alterar_dado(tabela TEXT, atualizacao TEXT, condicao TEXT) RETURNS VOID AS $$
DECLARE
    sql_command TEXT;
BEGIN
    sql_command := FORMAT('UPDATE %I SET %s WHERE %s', tabela, atualizacao, condicao);
    
    EXECUTE sql_command;
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Erro ao alterar dado: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION remover_dado(tabela TEXT, condicao TEXT) RETURNS VOID AS $$
DECLARE
    sql_command TEXT;
BEGIN    
    sql_command := FORMAT('DELETE FROM %I WHERE %s', tabela, condicao);
    
    EXECUTE sql_command;
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Erro ao remover dado: %', SQLERRM;
END;

$$ LANGUAGE plpgsql;
----- FUNCOES VENDA -----
CREATE OR REPLACE FUNCTION INICIAR_VENDA(CLIENTE_ID INT, FUNCIONARIO_ID INT)
RETURNS VOID AS $$
DECLARE ultima_matricula_do_cliente RECORD;
BEGIN 
    -- Conferir se o cliente existe
    IF NOT EXISTS(SELECT * FROM CLIENTE C WHERE C.ID_CLIENTE = CLIENTE_ID) THEN
        RAISE EXCEPTION 'Cliente de id % não encontrado!', CLIENTE_ID;
    END IF;

    -- Conferir se o funcionário existe
    IF NOT EXISTS(SELECT * FROM FUNCIONARIO F WHERE F.ID_FUNCIONARIO = FUNCIONARIO_ID) THEN
        RAISE EXCEPTION 'Funcionário de id % não encontrado!', FUNCIONARIO_ID;
    END IF;
	
	SELECT * into ultima_matricula_do_cliente FROM OBTER_ULTIMA_MATRICULA_DO_CLIENTE(CLIENTE_ID);

     -- Não vender para clientes que estão com a mensalidade atrasada
     IF ultima_matricula_do_cliente IS NOT NULL THEN
		IF (ultima_matricula_do_cliente.dt_vencimento < NOW()) THEN
        	RAISE EXCEPTION 'Cliente de id % É CALOREIRO, está com a matrícula atrasada!', CLIENTE_ID;
		END IF;
     END IF;

	 PERFORM INSERIR_DADOS(
        'venda', 
        'id_cliente, id_funcionario, qnt_produtos, valor_total, dt_venda', 
        format(' %s, %s, 0, 0, NOW()', CLIENTE_ID, FUNCIONARIO_ID)
    );

    RAISE INFO 'Cliente de id % iniciou uma venda', CLIENTE_ID; 
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION VISUALIZAR_VENDAS(CLIENTE_ID INT)
RETURNS TABLE (nome_funcionario VARCHAR, qnt_produtos int, valor_total decimal(10, 2), dt_venda TIMESTAMP, esta_ativa BOOLEAN)
AS $$
BEGIN
	RETURN QUERY
	SELECT
 	  f.nome nome_funcionario,
	  v.qnt_produtos,
	  v.valor_total,
	  v.dt_venda,
	  v.status <> 'CONCLUIDA' AND v.status <> 'CANCELADA' esta_ativa
	FROM
	  cliente c
	  NATURAL LEFT JOIN VENDA V
	  JOIN funcionario f ON f.id_funcionario = v.id_funcionario;
	
END
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION registrar_produto_na_compra(VENDA_ID INT, PRODUTO_ID INT , QUANTIDADE INT)
RETURNS VOID AS $$
BEGIN 
	IF NOT EXISTS(SELECT * FROM VENDA V WHERE V.ID_VENDA = VENDA_ID) THEN
		RAISE EXCEPTION 'Venda de id % não encontrada!', VENDA_ID;
	END IF;

	IF NOT EXISTS(SELECT * FROM PRODUTO P WHERE P.ID_PRODUTO = PRODUTO_ID) THEN
		RAISE EXCEPTION 'Produto de id % não encontrado!', PRODUTO_ID;
	END IF;

    -- CONFERIR na tabela item_venda se já existe algum produto está sendo vendido, se sim inserir dado
    IF NOT EXISTS( SELECT * FROM ITEM_VENDA WHERE ID_VENDA = VENDA_ID AND ID_PRODUTO = PRODUTO_ID) THEN
        PERFORM INSERIR_DADOS(
            'item_venda', 
            'id_produto, id_venda, quantidade', 
            format('%s, %s, %s', PRODUTO_ID, VENDA_ID, QUANTIDADE)
    );
    ELSE
        -- Se não, Alterar o registro que já existe
        PERFORM ALTERAR_DADO(
            'item_venda',
            format('quantidade = quantidade + %s', QUANTIDADE),
            format('id_venda = %s and id_produto = %s', venda_id, produto_id)
        );
        
    END IF;

	RAISE INFO 'INSERINDO % PRODUTOS NA VENDA %', quantidade, venda_id;
	
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
  PERFORM ALTERAR_DADO(
        'venda', 
        'status = ''CONCLUIDA'', dt_venda_final = NOW()', 
        FORMAT('id_venda = %s', VENDA_ID)
    );
    RAISE INFO 'Venda de id % confirmada!', VENDA_ID;
END;
$$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION CANCELAR_VENDA(venda_id int)
RETURNS VOID AS $$
DECLARE prod RECORD;
BEGIN
 IF NOT EXISTS (SELECT * FROM venda WHERE id_venda = venda_id AND status = 'PENDENTE') THEN
    RAISE EXCEPTION 'Venda de id % não encontrada ou já confirmada/cancelada!', VENDA_ID;
  END IF;

 UPDATE VENDA SET status='CANCELADA' WHERE ID_VENDA = VENDA_ID;

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

-- Remover um produto de uma venda
CREATE OR REPLACE FUNCTION REMOVER_PRODUTO_DA_VENDA(VENDA_ID INT, PRODUTO_ID INT, QTD INT)
RETURNS VOID AS $$
DECLARE
BEGIN
    -- Verificar se a venda existe
    IF NOT EXISTS (SELECT * FROM VENDA WHERE ID_VENDA = VENDA_ID) THEN
        RAISE EXCEPTION 'Venda de id % não encontrada!', VENDA_ID;
    END IF;
	
    -- Verificar se o produto existe
    IF NOT EXISTS (SELECT * FROM PRODUTO WHERE ID_PRODUTO = PRODUTO_ID) THEN
        RAISE EXCEPTION 'Produto de id % não encontrado!', PRODUTO_ID;
    END IF;

    -- Verificar se o produto existe na venda
    IF NOT EXISTS (SELECT * FROM ITEM_VENDA WHERE ID_VENDA = VENDA_ID AND ID_PRODUTO = PRODUTO_ID) THEN
        RAISE EXCEPTION 'Produto de id % não encontrado na venda de id %!', PRODUTO_ID, VENDA_ID;
    END IF;

    -- Verificar se a venda possui a quantidade de produtos a ser removida, por meio da tabela item_venda
    IF (SELECT QUANTIDADE FROM ITEM_VENDA WHERE ID_VENDA = VENDA_ID AND ID_PRODUTO = PRODUTO_ID) < QTD THEN
        RAISE EXCEPTION 'Venda de id % não possui % unidades do produto de id %!', VENDA_ID, QTD, PRODUTO_ID;
    END IF;

    -- Atualizar a quantidade de produtos na venda
    PERFORM ALTERAR_DADO (
        'item_venda',
        FORMAT('quantidade = quantidade - %s', QTD),
        FORMAT('id_venda = %s AND id_produto = %s', VENDA_ID, PRODUTO_ID)
    );
END;
$$
LANGUAGE PLPGSQL;

-- Função para obter a última compra pendente.
CREATE OR REPLACE FUNCTION OBTER_ID_DA_ULTIMA_VENDA_PENDENTE()
RETURNS INT AS $$
DECLARE
    VENDA_ID INT;
BEGIN
    SELECT ID_VENDA INTO VENDA_ID
    FROM VENDA
    WHERE STATUS = 'PENDENTE'
    ORDER BY ID_VENDA DESC
    LIMIT 1;

    RETURN VENDA_ID;
END;
$$ LANGUAGE PLPGSQL;

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
	PERFORM INSERIR_DADOS(
        'matricula',
        'id_cliente, id_funcionario, id_pacote, valor_pago, dt_pagamento, dt_vencimento',
        FORMAT('%s, %s, %s, %s, NOW(), NOW() + INTERVAL ''1 day'' * %s', 
            CLIENTE_ID, FUNCIONARIO_ID, PACOTE_ID, pacote.valor, pacote.duracao_dias)
  );
    
    RAISE INFO 'Matrícula do cliente de id % realizada pelo funcionário %', CLIENTE_ID, FUNCIONARIO_ID;
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
	
	-- Inserir novo plano de treino usando a função INSERIR_DADOS
    PERFORM INSERIR_DADOS(
        'plano_treino',
        'id_instrutor, objetivo, notas',
        FORMAT('%s, %L, %L', INSTRUTOR_ID, objetivo, notas)
    );

    -- Recuperar o ID do novo plano de treino (último ID inserido)
    SELECT currval(pg_get_serial_sequence('plano_treino', 'id_plano')) INTO id_novo_plano;

    -- Atualizar o cliente com o ID do novo plano de treino usando a função ALTERAR_DADO
    PERFORM ALTERAR_DADO(
        'cliente', 
        FORMAT('id_plano = %s', id_novo_plano), 
        FORMAT('id_cliente = %s', CLIENTE_ID)
    );

END;
$$ LANGUAGE plpgsql;

-- Adiciona um exercício à um plano de treino
CREATE OR REPLACE FUNCTION ADICIONAR_EXERCICIO_NO_TREINO(PLANO_ID INT, EXERCICIO_ID INT, REPETICOES INT, CARGA INT, NUM_DIA_SEMANA INT)
RETURNS VOID AS $$
BEGIN
	IF NOT EXISTS(SELECT * FROM PLANO_TREINO WHERE ID_PLANO = PLANO_ID) THEN
		RAISE EXCEPTION 'Treino % não existe!', PLANO_ID;
	END IF;
	
	IF NOT EXISTS(SELECT * FROM EXERCICIO WHERE ID_EXERCICIO = EXERCICIO_ID) THEN
		RAISE EXCEPTION 'Exercício % não existe!', TREINO_ID;
	END IF;

	IF NOT EXISTS(SELECT * FROM DIA_SEMANA WHERE ID_DIA = NUM_DIA_SEMANA) THEN
		RAISE EXCEPTION 'Dia da semana fornecido: %s inválido', NUM_DIA_SEMANA;
	END IF;
		
	
	PERFORM INSERIR_DADOS(
        'plano_treino_exercicio',
        'id_exercicio, id_plano, repeticoes, carga, dia_semana',
        FORMAT('%s, %s, %s, %s, %s', EXERCICIO_ID, PLANO_ID, REPETICOES, CARGA, NUM_DIA_SEMANA)
    );

  RAISE INFO 'Exercício % adicionado ao plano de treino %!', EXERCICIO_ID, PLANO_ID;


END;
$$
LANGUAGE PLPGSQL;



CREATE OR REPLACE FUNCTION ALTERAR_EXERCICIO_NO_TREINO(
    PLANO_ID INT, 
    EXERCICIO_ID INT,
    DIA_DA_SEMANA_ INT, 
    NOVAS_REPETICOES INT, 
    NOVA_CARGA INT, 
    NOVO_DIA_SEMANA INT
)
RETURNS VOID AS $$
DECLARE DIA_DA_SEMANA_STR VARCHAR;
BEGIN
    -- Verifica se o plano de treino existe
    IF NOT EXISTS (SELECT * FROM PLANO_TREINO WHERE ID_PLANO = PLANO_ID) THEN
        RAISE EXCEPTION 'Treino % não existe!', PLANO_ID;
    END IF;

    -- Verifica se o exercício existe
    IF NOT EXISTS (SELECT * FROM EXERCICIO WHERE ID_EXERCICIO = EXERCICIO_ID) THEN
        RAISE EXCEPTION 'Exercício % não existe!', EXERCICIO_ID;
    END IF;

    -- Verifica se o dia da semana fornecido é válido
    IF NOT EXISTS (SELECT * FROM DIA_SEMANA WHERE ID_DIA = NOVO_DIA_SEMANA) THEN
        RAISE EXCEPTION 'Dia da semana fornecido: %s inválido', NOVO_DIA_SEMANA;
    END IF;

	SELECT * INTO DIA_DA_SEMANA_STR FROM DIA_SEMANA WHERE ID_DIA = DIA_DA_SEMANA_;

    -- Verifica se a combinação exercício/plano/dia-da-semana existe
    IF EXISTS (SELECT * FROM PLANO_TREINO_EXERCICIO WHERE ID_EXERCICIO = EXERCICIO_ID AND ID_PLANO = PLANO_ID AND DIA_SEMANA = DIA_DA_SEMANA_) THEN
        UPDATE PLANO_TREINO_EXERCICIO
        SET 
            REPETICOES = NOVAS_REPETICOES,
            CARGA = NOVA_CARGA,
            DIA_SEMANA = NOVO_DIA_SEMANA
        WHERE ID_EXERCICIO = EXERCICIO_ID AND ID_PLANO = PLANO_ID AND DIA_SEMANA = DIA_DA_SEMANA_;
	
        RAISE INFO 'Exercício % que ocorre no(a) % no plano de treino % foi atualizado!', EXERCICIO_ID, DIA_DA_SEMANA_STR, PLANO_ID;
    ELSE
        RAISE EXCEPTION 'A combinação de exercício % e plano % não existe!', EXERCICIO_ID, PLANO_ID;
    END IF;
END;
$$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION DELETAR_EXERCICIO_DO_TREINO(
    PLANO_ID INT, 
    EXERCICIO_ID INT,
	DIA_DA_SEMANA INT
)
RETURNS VOID AS $$
BEGIN
    -- Verifica se o plano de treino existe
    IF NOT EXISTS (SELECT * FROM PLANO_TREINO WHERE ID_PLANO = PLANO_ID) THEN
        RAISE EXCEPTION 'Treino % não existe!', PLANO_ID;
    END IF;

    -- Verifica se o exercício existe
    IF NOT EXISTS (SELECT * FROM EXERCICIO WHERE ID_EXERCICIO = EXERCICIO_ID) THEN
        RAISE EXCEPTION 'Exercício % não existe!', EXERCICIO_ID;
    END IF;

		-- Verifica se o dia da semana eh valido
		IF NOT EXISTS (SELECT * FROM DIA_SEMANA WHERE ID_DIA = NOVO_DIA_SEMANA) THEN
        RAISE EXCEPTION 'Dia da semana fornecido: %s inválido', NOVO_DIA_SEMANA;
    END IF;

		-- DELETA CASO EXISTA A COMBINACAO DOS TRES
    IF EXISTS (SELECT * FROM PLANO_TREINO_EXERCICIO WHERE ID_EXERCICIO = EXERCICIO_ID AND ID_PLANO = PLANO_ID AND DIA_SEMANA = DIA_DA_SEMANA) THEN
        DELETE FROM PLANO_TREINO_EXERCICIO 
        WHERE ID_EXERCICIO = EXERCICIO_ID AND ID_PLANO = PLANO_ID AND DIA_SEMANA = DIA_DA_SEMANA;

        RAISE INFO 'Exercício % foi removido do plano de treino %!', EXERCICIO_ID, PLANO_ID;
    ELSE
        RAISE EXCEPTION 'A combinação de exercício % e plano % não existe!', EXERCICIO_ID, PLANO_ID;
    END IF;
END;
$$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION VISUALIZAR_PLANO_TREINO(CLIENTE_ID INT)
RETURNS TABLE 
(
	nome_exercicio VARCHAR, 
	equipamento VARCHAR, 
	carga NUMERIC, 
	repeticoes INT,
	dia_da_semana VARCHAR
) 
AS $$
BEGIN	
	
	IF (SELECT ID_PLANO FROM CLIENTE WHERE id_cliente = CLIENTE_ID) IS NULL THEN
		RAISE EXCEPTION 'Cliente de id % não possui nenhum plano de treino vinculado', CLIENTE_ID;
    END IF;

	RETURN QUERY
	SELECT 
		e.nome nome_exercicio,
		eq.nome equipamento,
		pte.carga carga,
		pte.repeticoes repeticoes,
		ds.nome_dia dia_da_semana
	FROM PLANO_TREINO pt
	JOIN CLIENTE c 
	ON c.id_plano = pt.id_plano 
	AND c.id_cliente = CLIENTE_ID
	JOIN PLANO_TREINO_EXERCICIO pte
	ON pt.id_plano = pte.id_plano
	JOIN exercicio e 
	ON e.id_exercicio = pte.id_exercicio
	JOIN DIA_SEMANA DS ON PTE.DIA_SEMANA = DS.ID_DIA
	LEFT JOIN equipamento eq ON e.id_eq = eq.id_eq;
	
END;
$$ LANGUAGE PLPGSQL;


CREATE FUNCTION VISUALIZAR_VENDAS_DO_CLIENTE(CLIENTE_ID INT)
RETURNS TABLE (nome_funcionario VARCHAR, qnt_produtos int, valor_total decimal(10, 2), dt_venda TIMESTAMP, esta_ativa BOOLEAN)
AS $$
BEGIN
	RETURN QUERY
	SELECT
 	  f.nome nome_funcionario,
	  v.qnt_produtos,
	  v.valor_total,
	  v.dt_venda,
	  v.status <> 'CONCLUIDA' OR v.status <> 'PENDENTE' esta_ativa
	FROM
	  cliente c
	  NATURAL LEFT JOIN VENDA V
	  JOIN funcionario f ON f.id_funcionario = v.id_funcionario;
	
END
$$ LANGUAGE PLPGSQL;