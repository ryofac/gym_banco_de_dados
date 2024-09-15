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
    -- Construa o comando SQL dinâmico para atualização
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
    -- Construa o comando SQL dinâmico para remoção
    sql_command := FORMAT('DELETE FROM %I WHERE %s', tabela, condicao);
    
    EXECUTE sql_command;
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Erro ao remover dado: %', SQLERRM;
END;

$$ LANGUAGE plpgsql;
----- FUNCOES VENDA -----
CREATE OR REPLACE FUNCTION INICIAR_VENDA(ID_CLIENTE INT, ID_FUNCIONARIO INT)
RETURNS VOID AS $$
BEGIN 
    -- Conferir se o cliente existe
    IF NOT EXISTS(SELECT * FROM CLIENTE C WHERE C.ID_CLIENTE = ID_CLIENTE) THEN
        RAISE EXCEPTION 'Cliente de id % não encontrado!', ID_CLIENTE;
    END IF;

    -- Conferir se o funcionário existe
    IF NOT EXISTS(SELECT * FROM FUNCIONARIO F WHERE F.ID_FUNCIONARIO = ID_FUNCIONARIO) THEN
        RAISE EXCEPTION 'Funcionário de id % não encontrado!', ID_FUNCIONARIO;
    END IF;

    -- Não vender para clientes que estão com a mensalidade atrasada
    IF NOT EXISTS(SELECT * FROM OBTER_ULTIMA_MATRICULA_DO_CLIENTE(ID_CLIENTE)) THEN
        RAISE EXCEPTION 'Cliente de id % não possui matrícula ativa!', ID_CLIENTE;
    END IF;

	 PERFORM INSERIR_DADOS(
        'venda', 
        'id_cliente, id_funcionario, qnt_produtos, valor_total, dt_venda', 
        format('DEFAULT, %s, %s, 0, 0, NOW()', ID_CLIENTE, ID_FUNCIONARIO)
    );
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
	
	PERFORM INSERIR_DADOS(
        'item_venda', 
        'id_produto, id_venda, quantidade', 
        format('%s, %s, %s', PRODUTO_ID, VENDA_ID, QUANTIDADE)
  );

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
  PERFORM ALTERAR_DADO(
        'venda', 
        'status = ''CONCLUIDA'', dt_venda_final = NOW()', 
        FORMAT('id_venda = %s', VENDA_ID)
    );
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
	PERFORM INSERIR_DADOS(
        'matricula',
        'id_cliente, id_funcionario, id_pacote, valor_pago, dt_pagamento, dt_vencimento',
        FORMAT('%s, %s, %s, %s, NOW(), NOW() + INTERVAL ''1 day'' * %s', 
            CLIENTE_ID, FUNCIONARIO_ID, PACOTE_ID, pacote.valor, pacote.duracao_dias)
  );
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
CREATE OR REPLACE FUNCTION ADICIONAR_EXERICIO_NO_TREINO(PLANO_ID INT, EXERCICIO_ID INT, REPETICOES INT, CARGA INT)
RETURNS VOID AS $$
BEGIN
	IF NOT EXISTS(SELECT * FROM PLANO_TREINO WHERE ID_PLANO = PLANO_ID) THEN
		RAISE EXCEPTION 'Treino % não existe!', PLANO_ID;
	END IF;
	
	IF NOT EXISTS(SELECT * FROM EXERCICIO WHERE ID_EXERCICIO = EXERCICIO_ID) THEN
		RAISE EXCEPTION 'Exercício % não existe!', TREINO_ID;
	END IF;
	
	PERFORM INSERIR_DADOS(
        'plano_treino_exercicio',
        'id_exercicio, id_plano, repeticoes, carga',
        FORMAT('%s, %s, %s, %s', EXERCICIO_ID, PLANO_ID, REPETICOES, CARGA)
    );

  RAISE INFO 'Exercício % adicionado ao plano de treino %!', EXERCICIO_ID, PLANO_ID;


END;
$$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION VISUALIZAR_PLANO_TREINO(CLIENTE_ID INT)
RETURNS TABLE 
(
	nome_exercicio VARCHAR, 
	equipamento VARCHAR, 
	carga NUMERIC, 
	repeticoes INT
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
		pte.repeticoes repeticoes
	FROM PLANO_TREINO pt
	JOIN CLIENTE c 
	ON c.id_plano = pt.id_plano 
	AND c.id_cliente = CLIENTE_ID
	JOIN PLANO_TREINO_EXERCICIO pte
	ON pt.id_plano = pte.id_plano
	JOIN exercicio e 
	ON e.id_exercicio = pte.id_exercicio
	LEFT JOIN equipamento eq ON e.id_eq = eq.id_eq;
	
END;
$$ LANGUAGE PLPGSQL;
