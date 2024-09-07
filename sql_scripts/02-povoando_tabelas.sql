-- VENDAS
INSERT INTO
  cliente (nome, cpf)
VALUES
  ('João Silva', '12345678901'),
  ('Maria Oliveira', '23456789012'),
  ('Carlos Souza', '34567890123');

INSERT INTO
  produto (nome, valor_unitario, qnt_em_estoque)
VALUES
  ('Suplemento Whey Protein', 120.50, 50),
  ('Camiseta Esportiva', 40.00, 100),
  ('Squeeze Fitness', 25.00, 200);

INSERT INTO
  funcionario (nome, telefone)
VALUES
  ('Ana Santos', '11987654321'),
  ('Lucas Lima', '11876543210');

-- ACADEMIA
INSERT INTO
  instrutor (nome, cpf, url_certificado)
VALUES
  (
    'João Silva',
    '12345678901',
    'http://certificados.exemplo.com/joao_silva.pdf'
  ),
  (
    'Maria Oliveira',
    '98765432100',
    'http://certificados.exemplo.com/maria_oliveira.pdf'
  ),
  (
    'Carlos Souza',
    '19283746500',
    'http://certificados.exemplo.com/carlos_souza.pdf'
  );

INSERT INTO
  equipamento (nome, descricao)
VALUES
  ('Esteira', 'Equipamento para corrida e caminhada'),
  (
    'Bicicleta Ergométrica',
    'Equipamento para exercícios de ciclismo'
  ),
  ('Halter', 'Equipamento para levantamento de peso');

INSERT INTO
  tipo_exercicio (regiao_trabalhada)
VALUES
  ('Cardiovascular'),
  ('Musculação'),
  ('Flexibilidade');

INSERT INTO
  exercicio (id_eq, id_tipo_exercicio, nome)
VALUES
  (1, 1, 'Corrida na Esteira'),
  (2, 1, 'Pedalada na Bicicleta'),
  (3, 2, 'Supino com Halter'),
  (3, 2, 'Rosca Direta com Halter'),
  (1, 3, 'Alongamento na Esteira');

INSERT INTO
  equipamento (nome, descricao)
VALUES
  ('Esteira', 'Equipamento para corrida e caminhada'),
  (
    'Bicicleta Ergométrica',
    'Equipamento para exercícios de ciclismo'
  ),
  ('Halter', 'Equipamento para levantamento de peso');

INSERT INTO
  pacote (nome, descricao, valor, duracao_dias)
VALUES
  (
    'Pacote Básico',
    'Acesso completo às instalações e participação em aulas coletivas básicas',
    99.99,
    30
  ), -- 30 dias
  (
    'Pacote Avançado',
    'Inclui todas as vantagens do Pacote Básico mais acesso a aulas especializadas e personal trainer',
    149.99,
    60
  ), -- 60 dias
  (
    'Pacote Premium',
    'Acesso total a todas as áreas da academia, incluindo sala VIP, sessões de treinamento individualizadas e consultas nutricionais',
    199.99,
    90
  ), -- 90 dias
  (
    'Pacote Mensal',
    'Acesso às instalações e aulas por um mês',
    89.99,
    30
  ), -- 30 dias
  (
    'Pacote Semestral',
    'Acesso às instalações e aulas por seis meses com desconto especial',
    499.99,
    180
  );

-- 180 dias