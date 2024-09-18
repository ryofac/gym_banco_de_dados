---- TRIGGERS AUDITORIA ----
CREATE OR REPLACE FUNCTION registrar_auditoria()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditoria (tabela, operacao, data_operacao, usuario)
    VALUES (
        TG_TABLE_NAME,
        TG_OP,                              
        NOW(),
				current_user
    );
    RETURN NEW;  -- Retorna o novo registro para operações INSERT e UPDATE
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auditoria
AFTER INSERT OR UPDATE OR DELETE ON matricula
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();

CREATE TRIGGER auditoria_produto
AFTER INSERT OR UPDATE OR DELETE ON produto
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();

CREATE TRIGGER auditoria_venda
AFTER INSERT OR UPDATE OR DELETE ON venda
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();

CREATE TRIGGER auditoria_cliente
AFTER INSERT OR UPDATE OR DELETE ON cliente
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();

CREATE TRIGGER auditoria_instrutor
AFTER INSERT OR UPDATE OR DELETE ON instrutor
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria();


----- TRIGGERS ITEM_VENDA ------
-- Trigger que decrementa a quantidade de um produto na tabela PRODUTO conforme for inserido em ITEM_VENDA
CREATE OR REPLACE FUNCTION decrementar_item_comprado()
RETURNS TRIGGER AS $$
DECLARE QNT_TOTAL_PRODUTO INT;
DECLARE NOME_PRODUTO VARCHAR;
DECLARE DIFERENCA_PRODUTO_ANTERIOR INT;
BEGIN
	SELECT qnt_em_estoque INTO QNT_TOTAL_PRODUTO from produto
	WHERE ID_PRODUTO = NEW.ID_PRODUTO;

	SELECT NOME INTO NOME_PRODUTO from produto
	WHERE ID_PRODUTO = NEW.ID_PRODUTO;


  IF (QNT_TOTAL_PRODUTO < 10) 
  THEN RAISE INFO 'Produto de id % está acabando! % restantes', NEW.ID_PRODUTO, QNT_TOTAL_PRODUTO;
  END IF;

	-- Caso inserção: atualizar somente a nova quantidade inserida
	IF TG_OP = 'INSERT' THEN

		IF (QNT_TOTAL_PRODUTO < NEW.QUANTIDADE) THEN
			RAISE EXCEPTION 'Quantidade em estoque (%) insuficiente para o produto %', QNT_TOTAL_PRODUTO, NOME_PRODUTO;
		END IF;

		UPDATE PRODUTO 
		SET qnt_em_estoque = qnt_em_estoque - NEW.QUANTIDADE
		WHERE id_produto = NEW.id_produto;
		RETURN NEW;
	END IF;

	-- Caso atualização: atualizar a diferença entre a quantidade anterior e a nova
	IF TG_OP = 'UPDATE' THEN

		IF (QNT_TOTAL_PRODUTO < (NEW.QUANTIDADE - OLD.QUANTIDADE)) THEN
			RAISE EXCEPTION 'Quantidade em estoque (%) insuficiente para o produto %', QNT_TOTAL_PRODUTO, NOME_PRODUTO;
		END IF;

		UPDATE PRODUTO
		SET qnt_em_estoque = qnt_em_estoque - (NEW.QUANTIDADE - OLD.QUANTIDADE)
		WHERE id_produto = NEW.id_produto;
		RETURN NEW;
	END IF;

END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_DECREMENTAR_ESTOQUE
AFTER INSERT OR UPDATE ON ITEM_VENDA
FOR EACH ROW
EXECUTE FUNCTION decrementar_item_comprado();

-- Trigger que atualiza informações de uma venda quando uma linha for inserida na tabela ITEM_VENDA
CREATE OR REPLACE FUNCTION ATUALIZAR_INFORMACOES_DA_VENDA()
RETURNS TRIGGER AS $$
DECLARE DIFF_QUANT INT;
BEGIN
		IF TG_OP = 'INSERT' THEN
			UPDATE venda
			SET qnt_produtos = qnt_produtos + NEW.quantidade,
					valor_total = valor_total + (SELECT valor_unitario FROM produto WHERE id_produto = NEW.id_produto) * NEW.quantidade
			WHERE id_venda = NEW.id_venda;
			
		END IF;

		
		IF TG_OP = 'UPDATE' THEN
			DIFF_QUANT := NEW.quantidade - OLD.quantidade;

			UPDATE venda
			SET qnt_produtos = qnt_produtos + DIFF_QUANT,
					valor_total = valor_total + (SELECT valor_unitario FROM produto WHERE id_produto = NEW.id_produto) * DIFF_QUANT
			WHERE id_venda = NEW.id_venda;

		END IF;

		RETURN NEW;


END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER TRG_ATUALIZAR_INFORMACOES_DA_VENDA
AFTER INSERT OR UPDATE ON ITEM_VENDA
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
RETURNS TABLE (id_matricula INT, id_cliente INT, id_pacote INT, dt_vencimento DATE, valor NUMERIC) AS $$
BEGIN

	RETURN QUERY
	SELECT M.id_matricula, M.id_cliente, M.id_pacote, M.dt_vencimento, M.valor_pago FROM MATRICULA M 
	WHERE M.ID_CLIENTE = CLIENTE_ID ORDER BY dt_vencimento desc limit 1; 
	
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION EH_MATRICULA_VALIDA(MATRICULA_ID INT)
RETURNS BOOLEAN AS $$
DECLARE matricula_vencimento RECORD;
BEGIN	
		SELECT DT_VENCIMENTO INTO matricula_vencimento FROM MATRICULA WHERE ID_MATRICULA = MATRICULA_ID;

	RETURN matricula_vencimento IS NOT NULL AND (matricula_vencimento.dt_vencimento) > NOW();
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

--  -- Aplica uma multa para uma matrícula, caso ela não tenha sido renovada dentro do prazo:
--  CREATE OR REPLACE FUNCTION aplicar_multa()
--  RETURNS TRIGGER AS $$
--  DECLARE
-- 	 ultimo_pagamento RECORD;
--      dias_atraso INT;
--      valor_multa DECIMAL;
--  BEGIN
--  		-- pegar o ultimo registro do cara na tabela
-- 		SELECT * INTO ultimo_pagamento FROM OBTER_ULTIMA_MATRICULA_DO_CLIENTE(NEW.ID_CLIENTE);
--  		-- verificar a data de vencimento, se for menor que hoje, aplica multa

--      IF ultimo_pagamento IS NOT NULL THEN
-- 		IF ultimo_pagamento.dt_vencimento > NEW.dt_pagamento THEN
-- 			RETURN NEW; -- Não houve multa
-- 		END IF;
		
-- 		-- Calcular o número de dias de atraso
--          dias_atraso := (NEW.dt_pagamento - ultimo_pagamento.dt_vencimento)::INT;

--          -- Definir o valor da multa (Exemplo: 2% do valor total por dia de atraso)
--          valor_multa := (NEW.valor_pago * 0.02 * dias_atraso);

--          -- Atualizar o valor pago com a multa
--          NEW.valor_pago := (NEW.valor_pago + valor_multa)::DECIMAL;

--          RAISE NOTICE 'Multa aplicada: R$%, por % dias de atraso.', valor_multa, dias_atraso;
--      END IF;

--      RETURN NEW;
--  END;
--  $$ LANGUAGE plpgsql;

--  CREATE TRIGGER trg_aplicar_multa
--  BEFORE INSERT OR UPDATE ON matricula
--  FOR EACH ROW
--  EXECUTE FUNCTION aplicar_multa();

-- Caso o cliente não esteja matriculado, ele não pode receber um plano de treino
CREATE OR REPLACE FUNCTION PROIBIR_PLANO_TREINO_PARA_CLIENTE_NAO_MATRICULADO()
RETURNS TRIGGER AS $$
DECLARE plano_alterado BOOLEAN;
BEGIN
	plano_alterado := (OLD.ID_PLANO IS DISTINCT FROM NEW.ID_PLANO);

	IF NOT EXISTS(SELECT * FROM OBTER_ULTIMA_MATRICULA_DO_CLIENTE(NEW.ID_CLIENTE)) 
	AND plano_alterado  -- Significa que estou alterando esse atributo
	THEN
	  RAISE EXCEPTION 'Cliente % não está matriculado!', NEW.ID_CLIENTE;
	 END IF;
	 RETURN NEW;
END
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_PROIBIR_PLANO_TREINO_PARA_CLIENTE_NAO_MATRICULADO
BEFORE UPDATE ON CLIENTE
FOR EACH ROW
EXECUTE FUNCTION PROIBIR_PLANO_TREINO_PARA_CLIENTE_NAO_MATRICULADO();

-- Caso o cliente já possua um plano de treino, ele não pode ser alterado
CREATE OR REPLACE FUNCTION PROIBIR_CLIENTE_COM_PLANO_ASSOSSIADO()
RETURNS TRIGGER AS $$
DECLARE plano_alterado BOOLEAN;
BEGIN
	-- Indica que o atributo sofreu alteracao, mas aceita nulos
	 plano_alterado :=  OLD.ID_PLANO <> NEW.ID_PLANO;

	 IF (SELECT ID_PLANO FROM CLIENTE C WHERE NEW.ID_CLIENTE = ID_CLIENTE) IS NOT NULL
	 AND plano_alterado
	 THEN
	  RAISE EXCEPTION 'Cliente % já possui um plano assossiado!', NEW.ID_CLIENTE;
	 END IF;
	 RETURN NEW;
END
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_PROIBIR_CLIENTE_COM_PLANO_ASSOSSIADO
BEFORE UPDATE ON CLIENTE
FOR EACH ROW
EXECUTE FUNCTION PROIBIR_CLIENTE_COM_PLANO_ASSOSSIADO();

-- Se existir algum plano de treino órfão, ou seja, nenhum cliente
-- esteja usando, ele é apagado.
CREATE OR REPLACE FUNCTION DELETAR_PLANO_TREINO_SE_NAO_USADO_MAIS()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.ID_PLANO IS NULL THEN
		-- SE NÃO ESTIVER SENDO MAIS USADO POR NINGUÉM NA TABELA CLIENTE
		IF (SELECT COUNT(*) FROM CLIENTE WHERE ID_PLANO = OLD.ID_PLANO) <= 0 THEN
			DELETE FROM PLANO_TREINO WHERE ID_PLANO = OLD.ID_PLANO;
			RAISE INFO 'Plano de treino de id % sendo apagado: Ninguém está usando ele', OLD.ID_PLANO;
		END IF;
	END IF;
	RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_DELETAR_PLANO_TREINO_SE_NAO_USADO_MAIS
AFTER UPDATE ON CLIENTE
FOR EACH ROW
EXECUTE FUNCTION DELETAR_PLANO_TREINO_SE_NAO_USADO_MAIS();

CREATE OR REPLACE FUNCTION PROIBIR_ATRIBUICAO_PLANO_TREINO_SE_CLIENTE_INATIVO()
RETURNS TRIGGER AS $$
DECLARE ultima_matricula RECORD;
DECLARE mudou_plano_treino BOOLEAN;
BEGIN 

	SELECT * INTO ultima_matricula
	FROM OBTER_ULTIMA_MATRICULA_DO_CLIENTE(NEW.ID_CLIENTE);

	mudou_plano_treino :=  NEW.id_plano <> OLD.id_plano;

	IF NOT EH_MATRICULA_VALIDA(ULTIMA_MATRICULA.id_matricula) AND mudou_plano_treino THEN
		RAISE EXCEPTION 'Cliente de id % está com a matrícula atrasada!', NEW.ID_CLIENTE;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_PROIBIR_MANIPULACAO_PLANO_TREINO_SE_CLIENTE_INATIVO
BEFORE UPDATE ON CLIENTE
FOR EACH ROW
EXECUTE FUNCTION PROIBIR_ATRIBUICAO_PLANO_TREINO_SE_CLIENTE_INATIVO();

CREATE OR REPLACE FUNCTION DAR_DESCONTO_CASO_CLIENTE_ATIVO()
RETURNS TRIGGER AS $$
DECLARE pacote RECORD;
DECLARE ultima_matricula RECORD;
DECLARE desconto DECIMAL;
BEGIN
	SELECT * INTO ultima_matricula FROM OBTER_ULTIMA_MATRICULA_DO_CLIENTE(NEW.ID_CLIENTE);
	
	IF EH_MATRICULA_VALIDA(ultima_matricula.id_matricula) THEN
		SELECT * INTO pacote 
		FROM OBTER_ULTIMA_MATRICULA_DO_CLIENTE(NEW.ID_CLIENTE) m 
		JOIN PACOTE p 
		ON p.id_pacote = m.id_pacote;
		
		desconto := pacote.valor * 0.25;
		
		NEW.valor_total := NEW.valor_total - desconto;
		
		RAISE INFO 'O cliente de id % é um cliente massa, ele está matriculado na academia! por isso ganhou um desconto de 25%% em cima do valor do pacote (R$%), que dá (R$%)', 
		NEW.ID_CLIENTE, pacote.valor, desconto;
		
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TRG_DAR_DESCONTO_CASO_CLIENTE_ATIVO
BEFORE UPDATE ON VENDA
FOR EACH ROW
WHEN (NEW.STATUS IS DISTINCT FROM OLD.STATUS)
EXECUTE FUNCTION DAR_DESCONTO_CASO_CLIENTE_ATIVO();


CREATE OR REPLACE FUNCTION proibir_exercicio_mesmo_dia()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM plano_treino_exercicio 
        WHERE id_plano = NEW.id_plano 
        AND dia_semana = NEW.dia_semana
    ) THEN
        RAISE EXCEPTION 'Não é permitido adicionar dois exercícios no mesmo plano de treino para o mesmo dia da semana: %', NEW.dia_semana;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_proibir_exercicio_mesmo_dia
BEFORE INSERT ON plano_treino_exercicio
FOR EACH ROW
EXECUTE FUNCTION proibir_exercicio_mesmo_dia();