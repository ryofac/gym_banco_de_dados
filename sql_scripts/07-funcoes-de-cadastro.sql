    -- Função para cadastrar um novo cliente
CREATE OR REPLACE FUNCTION CADASTRAR_CLIENTE(
    NOME VARCHAR, 
    CPF_CLIENTE VARCHAR(11)
)
RETURNS VOID AS $$
BEGIN
    -- Validar CPF
    IF LENGTH(CPF_CLIENTE) != 11 THEN
        RAISE EXCEPTION 'CPF % inválido!', CPF_CLIENTE;
    END IF;

    -- Verificar se o cliente já existe
    IF EXISTS(SELECT 1 FROM CLIENTE WHERE CLIENTE.CPF = CPF_CLIENTE) THEN
        RAISE EXCEPTION 'Cliente com CPF % já cadastrado!', CPF_CLIENTE;
    END IF;

    -- Inserir cliente na tabela usando a função INSERIR_DADOS
    PERFORM INSERIR_DADOS(
        'cliente',  
        'id_plano, nome, cpf',  
        format('NULL, %L, %L', NOME, CPF_CLIENTE) 
    );
    
    RAISE INFO 'Cliente % cadastrado com ID: %', NOME, (SELECT ID_CLIENTE FROM CLIENTE WHERE CPF = CPF_CLIENTE);
END;
$$
LANGUAGE plpgsql;


-- Função para cadastrar um novo instrutor
CREATE OR REPLACE FUNCTION CADASTRAR_INSTRUTOR(
    NOME VARCHAR, 
    CPF_INSTRUTOR VARCHAR(11),
    URL_CERTIFICADO VARCHAR(255)
)
RETURNS VOID AS $$
BEGIN
    -- Validar CPF
    IF LENGTH(CPF_INSTRUTOR) != 11 THEN
        RAISE EXCEPTION 'CPF % inválido!', CPF_INSTRUTOR;
    END IF;

    -- Verificar se o instrutor já existe
    IF EXISTS(SELECT * FROM INSTRUTOR WHERE CPF = CPF_INSTRUTOR) THEN
        RAISE EXCEPTION 'Instrutor com CPF % já cadastrado!', CPF_INSTRUTOR;
    END IF;

    PERFORM INSERIR_DADOS(
        'instrutor',  
        'id_instrutor, nome, cpf, url_certificado',  
        format('DEFAULT, %L, %L, %L', NOME, CPF_INSTRUTOR, URL_CERTIFICADO) 
    );
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION CADASTRAR_EXERCICIO(
    NOME VARCHAR,
    EQUIPAMENTO_ID INT,
    TIPO_ID INT
)
RETURNS VOID AS $$
BEGIN
    -- Verificar se o cliente já existe
    IF (EQUIPAMENTO_ID IS NOT NULL) AND (NOT EXISTS(SELECT 1 FROM EQUIPAMENTO WHERE ID_EQ = EQUIPAMENTO_ID)) THEN
        RAISE EXCEPTION 'Equipamento de id % inválido!', EQUIPAMENTO_ID;
    END IF;

    IF not exists (SELECT * FROM tipo_exercicio WHERE id_tipo_exercicio = TIPO_ID) THEN
        RAISE EXCEPTION 'Tipo de exercício inválido!';
    END IF;

    INSERT INTO EXERCICIO VALUES (DEFAULT, EQUIPAMENTO_ID, TIPO_ID, NOME);

END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION CADASTRAR_FUNCIONARIO (NOME VARCHAR, TELEFONE VARCHAR)
RETURNS VOID AS $$
BEGIN
    INSERT INTO FUNCIONARIO VALUES(DEFAULT, NOME, TELEFONE);
END 
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION CADASTRAR_PRODUTO (NOME VARCHAR, VALOR_UNITARIO DECIMAL, qnt_em_estoque INT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO PRODUTO VALUES(DEFAULT, NOME, VALOR_UNITARIO, qnt_em_estoque);
END
$$ LANGUAGE PLPGSQL;