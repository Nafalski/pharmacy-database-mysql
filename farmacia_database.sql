-- ============================================================================
-- Drogaria Sampaio's — Base de Dados (MySQL)
-- Autor: Marco Yamin nº14
-- ============================================================================

-- 0) ELIMINAÇÃO E CRIAÇÃO DA BASE DE DADOS
DROP DATABASE IF EXISTS sampaio;  
-- Apaga a base de dados se ela já existir (serve pra começar do zero).

CREATE DATABASE sampaio CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
-- Cria a base de dados "sampaio" com suporte completo a acentos, emojis e caracteres especiais.

USE sampaio;  
-- Seleciona a base para começar a criar as tabelas dentro dela.

-- ============================================================================
-- 1) TABELAS (em 3FN = Terceira Forma Normal)
-- ============================================================================

-- 1.1 Clientes
CREATE TABLE clientes (
  cliente_id INT AUTO_INCREMENT PRIMARY KEY,   -- ID único para cada cliente (gera automaticamente).
  nome VARCHAR(150) NOT NULL,                  -- Nome obrigatório (NOT NULL = não pode ser vazio).
  nif VARCHAR(20) UNIQUE,                      -- NIF (como CPF), deve ser único se existir.
  email VARCHAR(200),
  telefone VARCHAR(50),
  morada VARCHAR(250),
  data_registo TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Data automática de registro do cliente.
  ativo BOOLEAN NOT NULL DEFAULT TRUE,              -- Define se o cliente está ativo (por padrão, TRUE).
  limite_credito DECIMAL(12,2) NOT NULL DEFAULT 0.00, -- Limite de crédito com 2 casas decimais.
  CHECK (limite_credito >= 0)                      -- Garante que o limite de crédito não seja negativo.
);

-- 1.2 Fornecedores
CREATE TABLE fornecedores (
  fornecedor_id INT AUTO_INCREMENT PRIMARY KEY,  -- ID do fornecedor (único e automático).
  nome VARCHAR(150) NOT NULL,
  nif VARCHAR(20) UNIQUE,                        -- Impede dois fornecedores com o mesmo NIF.
  email VARCHAR(200),
  telefone VARCHAR(50),
  morada VARCHAR(250),
  ativo BOOLEAN NOT NULL DEFAULT TRUE            -- Define se o fornecedor ainda está ativo.
);

-- 1.3 Produtos
CREATE TABLE produtos (
  produto_id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(200) NOT NULL,
  codigo VARCHAR(50) UNIQUE NOT NULL,            -- Código do produto (único, tipo “AG-500”).
  fornecedor_id INT NOT NULL,                    -- Ligação com a tabela de fornecedores.
  preco_base DECIMAL(12,2) NOT NULL,             -- Preço sem IVA.
  taxa_iva DECIMAL(5,2) NOT NULL,                -- Percentual do IVA (ex: 23.00).
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  CHECK (preco_base >= 0),                       -- Impede preço negativo.
  CHECK (taxa_iva >= 0 AND taxa_iva <= 100),     -- Garante que o IVA fique entre 0% e 100%.
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(fornecedor_id)
  -- FOREIGN KEY = chave estrangeira que liga o produto ao seu fornecedor.
);

-- 1.4 Faturas (cabeçalho)
CREATE TABLE facturas (
  factura_id INT AUTO_INCREMENT PRIMARY KEY,
  numero VARCHAR(30) NOT NULL UNIQUE,            -- Número da fatura (ex: FT 2025/0001).
  cliente_id INT NOT NULL,                       -- Ligação com a tabela de clientes.
  data_emissao TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Data automática da emissão.
  estado ENUM('RASCUNHO','EMITIDA','ANULADA') NOT NULL DEFAULT 'EMITIDA',
  -- ENUM = tipo que só aceita os valores indicados acima.
  observacoes TEXT,                              -- Campo livre para anotações.
  FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id)
  -- Conecta a fatura ao cliente correspondente.
);

-- 1.5 Linhas da fatura
CREATE TABLE linhas_factura (
  linha_id INT AUTO_INCREMENT PRIMARY KEY,      -- Cada linha da fatura tem um ID próprio.
  factura_id INT NOT NULL,                      -- Liga a linha a uma fatura.
  produto_id INT NOT NULL,                      -- Liga a linha a um produto.
  quantidade DECIMAL(12,3) NOT NULL,            -- Quantidade vendida (pode ter 3 casas decimais).
  preco_unitario DECIMAL(12,2) NOT NULL,        -- Preço unitário do produto.
  desconto_percent DECIMAL(5,2) NOT NULL DEFAULT 0, -- Desconto em % (por padrão 0%).
  taxa_iva DECIMAL(5,2) NOT NULL,               -- IVA aplicado nessa linha.
  CHECK (quantidade > 0),
  CHECK (preco_unitario >= 0),
  CHECK (desconto_percent >= 0 AND desconto_percent <= 100),
  CHECK (taxa_iva >= 0 AND taxa_iva <= 100),
  FOREIGN KEY (factura_id) REFERENCES facturas(factura_id) ON DELETE CASCADE,
  -- Se a fatura for apagada, todas as linhas dela também são apagadas (CASCADE).
  FOREIGN KEY (produto_id) REFERENCES produtos(produto_id)
);

-- 1.6 Pagamentos
CREATE TABLE pagamentos (
  pagamento_id INT AUTO_INCREMENT PRIMARY KEY,
  factura_id INT NULL,                          -- Pode estar ligado a uma fatura ou ser um pagamento avulso.
  cliente_id INT NOT NULL,
  data_pagamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  valor DECIMAL(12,2) NOT NULL,                 -- Valor pago.
  metodo ENUM('DINHEIRO','CARTAO','TRANSFERENCIA','CREDITO_LOJA') NOT NULL DEFAULT 'DINHEIRO',
  -- Método de pagamento (só pode ser um dos listados acima).
  observacoes TEXT,
  CHECK (valor > 0),                            -- O valor precisa ser positivo.
  FOREIGN KEY (factura_id) REFERENCES facturas(factura_id) ON DELETE SET NULL,
  -- Se a fatura for apagada, o campo vira NULL (não apaga o pagamento).
  FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id)
);

-- 1.7 Créditos do cliente
CREATE TABLE creditos_cliente (
  credito_id INT AUTO_INCREMENT PRIMARY KEY,
  cliente_id INT NOT NULL,
  data_lancamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  descricao VARCHAR(200),
  valor DECIMAL(12,2) NOT NULL,                 -- Pode ser positivo (bônus) ou negativo (uso de crédito).
  referencia VARCHAR(50),
  CHECK (valor <> 0),                           -- Impede valor zero.
  FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id)
);

-- ============================================================================
-- 2) DADOS DE EXEMPLO
-- ============================================================================

-- Inserindo fornecedores (2 empresas)
INSERT INTO fornecedores (nome, nif, email, telefone, morada) VALUES
('Químicos Alfa, Lda.', 'PT500000001', 'contacto@alfa.com', '+351 210000001', 'Rua da Indústria 10, Lisboa'),
('Higiene Beta SA', 'PT500000002', 'vendas@beta.pt', '+351 220000002', 'Av. Central 55, Porto');

-- Inserindo clientes (3 clientes diferentes)
INSERT INTO clientes (nome, nif, email, telefone, morada, limite_credito) VALUES
('Farmácia do Bairro', 'PT123456789', 'geral@farmbairro.pt', '+351 910000001', 'Rua das Flores 12, Lisboa', 1500.00),
('Clínica Saúde+', 'PT987654321', 'compras@saudemais.pt', '+351 930000002', 'Av. Saúde 200, Porto', 2500.00),
('Cliente avulso', NULL, NULL, NULL, NULL, 0.00);

-- Inserindo produtos (cada um ligado a um fornecedor)
INSERT INTO produtos (nome, codigo, fornecedor_id, preco_base, taxa_iva) VALUES
('Álcool Gel 500ml', 'AG-500', 2, 3.20, 23.00),
('Luvas Nitrilo M c/100', 'LUV-M-100', 2, 6.90, 23.00),
('Soro Fisiológico 250ml', 'SF-250', 1, 1.10, 6.00),
('Algodão 100g', 'ALG-100', 1, 0.85, 6.00);

-- Inserindo faturas
INSERT INTO facturas (numero, cliente_id, estado, observacoes) VALUES
('FT 2025/0001', 1, 'EMITIDA', 'Entrega imediata'),
('FT 2025/0002', 1, 'EMITIDA', NULL),
('FT 2025/0003', 2, 'EMITIDA', 'Prioridade'),
('FT 2025/0004', 3, 'ANULADA', 'Erro de lançamento');

-- Inserindo linhas das faturas (detalhes de produtos vendidos)
INSERT INTO linhas_factura (factura_id, produto_id, quantidade, preco_unitario, desconto_percent, taxa_iva) VALUES
(1, 1, 50, 3.10, 0, 23.00),
(1, 3, 30, 1.10, 5, 6.00),
(2, 2, 20, 6.80, 10, 23.00),
(2, 4, 40, 0.80, 0, 6.00),
(3, 1, 100, 3.00, 0, 23.00),
(3, 2, 50, 6.70, 5, 23.00),
(4, 1, 10, 3.20, 0, 23.00);

-- Inserindo pagamentos (liga faturas e clientes aos valores pagos)
INSERT INTO pagamentos (factura_id, cliente_id, valor, metodo, observacoes) VALUES
(1, 1, 150.00, 'TRANSFERENCIA', 'Parcial FT 2025/0001'),
(NULL, 1, 50.00, 'CREDITO_LOJA', 'Adiantamento a conta'),
(3, 2, 300.00, 'CARTAO', 'Parcial FT 2025/0003');

-- Inserindo créditos (bônus e ajustes manuais)
INSERT INTO creditos_cliente (cliente_id, descricao, valor, referencia) VALUES
(1, 'Bónus fidelização', 40.00, 'BONUS-OUT/25'),
(1, 'Uso de crédito em FT 2025/0002', -30.00, 'FT 2025/0002'),
(2, 'Ajuste comercial', 25.00, 'AJ-251029');

-- ============================================================================
-- 3) VIEWS (relatórios simulados)
-- ============================================================================

-- 3.1 Listagem de faturas
CREATE OR REPLACE VIEW v_listagem_facturas AS
SELECT
  f.numero,  -- número da fatura
  DATE(f.data_emissao) AS data_emissao,  -- só a data (sem hora)
  c.nome AS cliente,                     -- nome do cliente
  f.estado,                              -- estado da fatura (emitida, anulada, etc)
  -- Cálculo dos totais:
  ROUND(SUM(l.quantidade * l.preco_unitario * (1 - l.desconto_percent/100)),2) AS base,  -- total sem IVA
  ROUND(SUM(l.quantidade * l.preco_unitario * (1 - l.desconto_percent/100) * l.taxa_iva/100),2) AS iva,  -- valor do IVA
  ROUND(SUM(l.quantidade * l.preco_unitario * (1 - l.desconto_percent/100) * (1 + l.taxa_iva/100)),2) AS total  -- total final
FROM facturas f
JOIN linhas_factura l ON l.factura_id = f.factura_id   -- junta as faturas com suas linhas
JOIN clientes c ON c.cliente_id = f.cliente_id         -- junta com os clientes
GROUP BY f.factura_id, f.numero, f.data_emissao, c.nome, f.estado  -- agrupa cada fatura
ORDER BY f.data_emissao;  -- ordena pela data

-- 3.2 Saldos dos clientes
CREATE OR REPLACE VIEW v_saldo_clientes AS
SELECT 
  c.cliente_id,
  c.nome AS cliente,
  IFNULL(SUM(fv.total),0) AS total_em_aberto,       -- total das faturas emitidas
  IFNULL(SUM(pg.valor),0) AS total_pagamentos,      -- total pago pelo cliente
  IFNULL(SUM(cr.valor),0) AS total_creditos,        -- total de créditos (bônus, ajustes)
  ROUND(IFNULL(SUM(cr.valor),0) + IFNULL(SUM(pg.valor),0) - IFNULL(SUM(fv.total),0), 2) AS saldo_final
  -- cálculo: créditos + pagamentos - faturas = saldo final
FROM clientes c
-- Subconsulta (fv) calcula o total das faturas de cada cliente
LEFT JOIN (
  SELECT f.cliente_id, SUM(l.quantidade * l.preco_unitario * (1 - l.desconto_percent/100) * (1 + l.taxa_iva/100)) AS total
  FROM facturas f
  JOIN linhas_factura l ON l.factura_id = f.factura_id
  WHERE f.estado = 'EMITIDA'
  GROUP BY f.cliente_id
) fv ON fv.cliente_id = c.cliente_id
LEFT JOIN pagamentos pg ON pg.cliente_id = c.cliente_id
LEFT JOIN creditos_cliente cr ON cr.cliente_id = c.cliente_id
GROUP BY c.cliente_id, c.nome
ORDER BY c.nome;

-- ============================================================================
-- 4) CONSULTAS DE TESTE
-- ============================================================================
SELECT * FROM v_listagem_facturas;   -- mostra o relatório de todas as faturas
SELECT * FROM v_saldo_clientes;      -- mostra o saldo (dívida ou crédito) de cada cliente
