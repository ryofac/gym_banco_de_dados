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

-- Função para cadastrar um novo instrutor
CREATE OR REPLACE FUNCTION CADASTRAR_INSTRUTOR(
    NOME VARCHAR, 
    CPF VARCHAR(11),
    URL_CERTIFICADO VARCHAR(255)
)
RETURNS VOID AS $$
BEGIN
    -- Validar CPF
    IF LENGTH(CPF) != 11 THEN
        RAISE EXCEPTION 'CPF % inválido!', CPF;
    END IF;

    -- Verificar se o instrutor já existe
    IF EXISTS(SELECT * FROM INSTRUTOR WHERE CPF = CPF) THEN
        RAISE EXCEPTION 'Instrutor com CPF % já cadastrado!', CPF;
    END IF;

    -- Inserir instrutor na tabela
    INSERT INTO INSTRUTOR VALUES(DEFAULT, NOME, CPF, URL_CERTIFICADO);
END;
$$


