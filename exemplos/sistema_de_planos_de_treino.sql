-- Exemplo do sistema de matrĩcula
-- Cadastrando cliente Roberto
SELECT
  CADASTRAR_CLIENTE ('Patrocínio', '08197150346');

-- Cadastrando instrutor Thiago Elias
SELECT
  CADASTRAR_INSTRUTOR (
    'Thiago Elias',
    '12332112309',
    'file:///certificado_supremo.pdf'
  );

-- Criando o plano de treino para o cliente 4 e instrutor 4
-- Falha: Cliente não matriculado
SELECT
  CRIAR_PLANO_DE_TREINO (
    4,
    4,
    'Crescer bastante o abdomen',
    'Nenhuma nota'
  );

-- Matriculando cliente Patrocínio
SELECT
  REALIZAR_MATRICULA (4, 1, 1);

-- Agora posso criar o plano de treino tranquilamente:
SELECT
  CRIAR_PLANO_DE_TREINO (
    4,
    4,
    'Crescer bastante o abdomen',
    'Nenhuma nota'
  );

--  ADICIONANDO EXERCÍCIOS NO PLANO DE TREINO
--  FUNCTION ADICIONAR_EXERCICIO_NO_TREINO(PLANO_ID INT, EXERCICIO_ID INT, REPETICOES INT, CARGA INT, DiA_SEMANA INT)
SELECT
  ADICIONAR_EXERCICIO_NO_TREINO (2, 1, 0, 0, 2);

SELECT
  ADICIONAR_EXERCICIO_NO_TREINO (2, 4, 3, 15, 3);

-- Ver plano de treino no Patrocínio
-- FUNCTION VISUALIZAR_PLANO_TREINO(CLIENTE_ID INT)
SELECT
  *
FROM
  VISUALIZAR_PLANO_TREINO (4);

-- Alterando exercício no treino:
-- ALTERAR_EXERCICIO_NO_TREINO(
--    PLANO_ID INT, 
--    EXERCICIO_ID INT,
--    DIA_DA_SEMANA_ INT, 
--    NOVAS_REPETICOES INT, 
--    NOVA_CARGA INT, 
--    NOVO_DIA_SEMANA INT
--)
SELECT
  alterar_exercicio_no_treino (2, 4, 3, 10, 10, 4);

SELECT
  *
FROM
  VISUALIZAR_PLANO_TREINO (4);

-- Auditoria
SELECT
  *
FROM
  auditoria a;