CREATE TABLE
   produto (
      id_produto SERIAL PRIMARY KEY,
      nome VARCHAR(50),
      valor_unitario DECIMAL,
      qnt_em_estoque INT
   );

CREATE TABLE
   funcionario (
      id_funcionario SERIAL PRIMARY KEY,
      nome VARCHAR(255),
      telefone VARCHAR(20),
      INATIVO BOOLEAN DEFAULT FALSE
   );

CREATE TABLE
   instrutor (
      id_instrutor SERIAL PRIMARY KEY,
      nome VARCHAR(255),
      cpf VARCHAR(11),
      url_certificado VARCHAR(255)
   );

CREATE TABLE
   pacote (
      id_pacote SERIAL PRIMARY KEY,
      nome VARCHAR(50),
      descricao VARCHAR(255),
      valor DECIMAL,
      duracao_dias INT
   );

CREATE TABLE
   equipamento (
      id_eq SERIAL PRIMARY KEY,
      nome VARCHAR(50),
      descricao VARCHAR(255)
   );

CREATE TABLE
   tipo_exercicio (
      id_tipo_exercicio SERIAL PRIMARY KEY,
      regiao_trabalhada VARCHAR(50)
   );

CREATE TABLE
   exercicio (
      id_exercicio SERIAL PRIMARY KEY,
      id_eq INT REFERENCES equipamento (id_eq) NULL,
      id_tipo_exercicio INT REFERENCES tipo_exercicio (id_tipo_exercicio) ON DELETE CASCADE,
      nome VARCHAR(50)
   );

CREATE TABLE
   plano_treino (
      id_plano SERIAL PRIMARY KEY,
      id_instrutor INT REFERENCES instrutor (id_instrutor),
      objetivo VARCHAR(255),
      notas VARCHAR(255)
   );

-- Entidades base
CREATE TABLE
   cliente (
      id_cliente SERIAL PRIMARY KEY,
      id_plano INT REFERENCES PLANO_TREINO (id_plano) ON DELETE SET NULL DEFAULT NULL,
      nome VARCHAR(255),
      cpf VARCHAR(11) UNIQUE,
      INATIVO BOOLEAN DEFAULT FALSE
   );

-- Sistema base da academia:
CREATE TABLE
   matricula (
      id_matricula SERIAL PRIMARY KEY,
      id_cliente INT REFERENCES cliente (id_cliente),
      id_funcionario INT REFERENCES funcionario (id_funcionario),
      id_pacote INT REFERENCES pacote (id_pacote),
      valor_pago DECIMAL,
      dt_pagamento DATE,
      dt_vencimento DATE
   );

-- Tabela acessória para computar o dia da semana de determinado
-- exercício
CREATE TABLE
   dia_semana (
      id_dia INT PRIMARY KEY,
      nome_dia VARCHAR(15) NOT NULL
   );

INSERT INTO
   dia_semana (id_dia, nome_dia)
VALUES
   (1, 'Domingo'),
   (2, 'Segunda-feira'),
   (3, 'Terça-feira'),
   (4, 'Quarta-feira'),
   (5, 'Quinta-feira'),
   (6, 'Sexta-feira'),
   (7, 'Sábado');

CREATE TABLE
   plano_treino_exercicio (
      id_exercicio INT REFERENCES exercicio (id_exercicio) ON DELETE CASCADE,
      id_plano INT REFERENCES plano_treino (id_plano) ON DELETE CASCADE,
      repeticoes INT,
      carga DECIMAL,
      dia_semana INT REFERENCES DIA_SEMANA (ID_DIA)
   );

-- Sistema de vendas
CREATE TABLE
   venda (
      id_venda SERIAL PRIMARY KEY,
      id_cliente INT REFERENCES cliente (id_cliente),
      id_funcionario INT REFERENCES funcionario (id_funcionario),
      qnt_produtos INT,
      valor_total DECIMAL,
      dt_venda TIMESTAMP,
      dt_venda_final TIMESTAMP DEFAULT NULL,
      status VARCHAR(20) DEFAULT 'PENDENTE',
      CHECK (status IN ('CONCLUIDA', 'PENDENTE', 'CANCELADA'))
   );

CREATE TABLE
   item_venda (
      id_produto INT REFERENCES produto (id_produto) ON DELETE CASCADE,
      id_venda INT REFERENCES venda (id_venda) ON DELETE CASCADE,
      quantidade INT
   );

CREATE TABLE
   auditoria (
      id SERIAL PRIMARY KEY,
      tabela VARCHAR NOT NULL,
      operacao VARCHAR NOT NULL,
      data_operacao TIMESTAMP DEFAULT NOW (),
      usuario VARCHAR
   );