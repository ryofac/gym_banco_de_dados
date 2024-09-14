-- Função para cadastrar um novo cliente
CREATE OR REPLACE FUNCTION CADASTRAR_CLIENTE(
    NOME VARCHAR, 
    CPF VARCHAR(11)
)
RETURNS VOID AS $$
BEGIN
    -- Validar CPF
    IF LENGTH(CPF) != 11 THEN
        RAISE EXCEPTION 'CPF % inválido!', CPF;
    END IF;

    -- Verificar se o cliente já existe
    IF EXISTS(SELECT * FROM CLIENTE WHERE CPF = CPF) THEN
        RAISE EXCEPTION 'Cliente com CPF % já cadastrado!', CPF;
    END IF;

    -- Inserir cliente na tabela
    INSERT INTO CLIENTE VALUES(DEFAULT, NULL, NOME, CPF);
END;
$$
LANGUAGE plpgsql;


