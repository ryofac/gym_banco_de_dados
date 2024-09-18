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

