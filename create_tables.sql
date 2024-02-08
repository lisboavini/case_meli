-- ##############################################################
-- A primeira parte do arquivo contém as DDLs para criação das tabelas
-- considerando a abordagem de um banco de dados transacional para aplicação.
-- A segunda parte cria as tabelas de um modelo star-schema (fato e dimensão)
-- para geração de consultas e relatório segundo as necessidades apontadas.
-- ##############################################################
--MODELAGEM TRANSACIONAL
--DDL TABELA CUSTOMER
CREATE TABLE Customer (
    customer_id SERIAL PRIMARY KEY,
    customer_type VARCHAR(1) NOT NULL,
    nome VARCHAR(50) NOT NULL,
    sobrenome VARCHAR(50) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    cpf_cnpj NUMERIC(14) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    sexo VARCHAR(1) NOT NULL,
    endereco VARCHAR(100) NOT NULL,
    data_nasc DATE NOT NULL,
    telefone NUMERIC(11) NOT NULL,
    flag_status VARCHAR(1) NOT NULL,
    data_criacao TIMESTAMP NOT NULL,
    data_cancelamento TIMESTAMP,
    data_update TIMESTAMP NOT NULL
);

--DDL TABELA ITEM
CREATE TABLE Item (
    item_id SERIAL PRIMARY KEY,
    label VARCHAR(50) NOT NULL,
    descricao VARCHAR(500) NOT NULL,
    preco DECIMAL(12, 2) NOT NULL,
    type_new_old VARCHAR(3) NOT NULL,
    url_site VARCHAR(300) NOT NULL,
    flag_status VARCHAR(1) NOT NULL,
    data_inclusao TIMESTAMP NOT NULL,
    data_cancelamento TIMESTAMP,
    data_update TIMESTAMP NOT NULL,
    qtd_disponivel INT NOT NULL,
    fk_seller_id INT, 
    fk_category_id INT,
    CONSTRAINT fk_seller_id
        FOREIGN KEY(fk_seller_id)
            REFERENCES Customer(customer_id),
    CONSTRAINT fk_category_id
        FOREIGN KEY(fk_category_id)
            REFERENCES Category(category_id)
);

--DDL TABELA CATEGORY
CREATE TABLE Category (
    category_id SERIAL PRIMARY KEY,
    label VARCHAR(50) NOT NULL,
    descricao VARCHAR(500) NOT NULL,
    flag_status VARCHAR(1) NOT NULL,
    path_navegacao VARCHAR(100) NOT NULL,
    data_inclusao TIMESTAMP NOT NULL,
    data_cancelamento TIMESTAMP,
    data_update TIMESTAMP NOT NULL
);

--DDL TABELA ORDER
CREATE TABLE Order (
    order_id SERIAL PRIMARY KEY,
    fk_buyer_id INT NOT NULL,
    fk_seller_id INT NOT NULL,
    fk_item_id INT NOT NULL,
    fk_preco DECIMAL(12,2) NOT NULL,
    qtd_items DECIMAL(10) NOT NULL,
    valor_total DECIMAL(12,2) NOT NULL,
    data_compra TIMESTAMP NOT NULL,
    flag_status VARCHAR(1) NOT NULL,
    metodo_pagamento VARCHAR(1) NOT NULL,
    endereco_entrega VARCHAR(100) NOT NULL,
    previsao_entrega TIMESTAMP,
    mes_ref INT NOT NULL,
    ano_ref INT NOT NULL,
    data_update TIMESTAMP NOT NULL,
    data_cancelamento TIMESTAMP,
    CONSTRAINT fk_buyer_id
        FOREIGN KEY(fk_buyer_id)
            REFERENCES Customer(customer_id),
    CONSTRAINT fk_seller_id
        FOREIGN KEY(fk_seller_id)
            REFERENCES Customer(customer_id),
    CONSTRAINT fk_item_id
        FOREIGN KEY(fk_item_id)
            REFERENCES Item(item_id),
    CONSTRAINT fk_preco
        FOREIGN KEY(fk_preco)
            REFERENCES Item(preco),
);

--DDL TABELA FECHAMENTO_DIA
CREATE TABLE FechamentoDia (
    fechamento_dia_id SERIAL PRIMARY KEY,
    data_ref_fec DATE NOT NULL DEFAULT CURRENT_DATE,
    fk_item_id INT NOT NULL,
    fk_preco DECIMAL(12,2) NOT NULL,
    fk_seller_id INT NOT NULL,
    fk_category_id INT NOT NULL,
    qtd_vendida INT NOT NULL,
    qtd_disponivel INT NOT NULL,
    flag_fechamento VARCHAR(1) NOT NULL,
    data_inclusao TIMESTAMP NOT NULL,
    data_cancelamento TIMESTAMP,
    data_update TIMESTAMP NOT NULL,
    CONSTRAINT fk_item_id
        FOREIGN KEY(fk_item_id)
            REFERENCES Item(item_id),
    CONSTRAINT fk_preco
        FOREIGN KEY(fk_preco)
            REFERENCES Item(preco),
    CONSTRAINT fk_seller_id
        FOREIGN KEY(fk_seller_id)
            REFERENCES Customer(customer_id),
    CONSTRAINT fk_category_id
        FOREIGN KEY(fk_category_id)
            REFERENCES Category(category_id)
);

--###############################################################
--MODELAGEM STAR SCHEMA
--DDL TABELA FATO_ORDER
CREATE TABLE FATO_ORDER (
    fato_order_id SERIAL PRIMARY KEY,
    sk_seller_id INT NOT NULL,
    sk_buyer_id INT NOT NULL,
    category_id INT NOT NULL,
    item_id INT NOT NULL,
    date_id INT NOT NULL,
    total_qtd_vendas INT NOT NULL,
    total_qtd_items_vendas INT NOT NULL,
    valor_vendas DECIMAL NOT NULL,
    total_vendas_concluidas INT NOT NULL,
    total_qtd_compras INT NOT NULL,
    valor_compras DECIMAL NOT NULL,
    total_compras_concluidas INT NOT NULL
);

--DDL TABELA DIM_CUSTOMER_BUYER
CREATE TABLE DIM_CUSTOMER_BUYER (
    sk_buyer_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    nome VARCHAR(50) NOT NULL,
    sobrenome VARCHAR(50) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    cpf_cnpj DECIMAL(14) NOT NULL,
    endereco VARCHAR(100) NOT NULL,
    data_nasc DATE NOT NULL
);

--DDL TABELA DIM_CUSTOMER_SELLER
CREATE TABLE DIM_CUSTOMER_SELLER (
    sk_seller_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    nome VARCHAR(50) NOT NULL,
    sobrenome VARCHAR(50) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    cpf_cnpj DECIMAL(14) NOT NULL,
    endereco VARCHAR(100) NOT NULL,
    data_nasc DATE NOT NULL
);

--DDL TABELA DIM_ITEM
CREATE TABLE DIM_ITEM (
    item_id SERIAL PRIMARY KEY,
    category_id INT NOT NULL,
    sk_seller_id INT NOT NULL,
    label VARCHAR(50) NOT NULL,
    qtd_disponivel INT NOT NULL,
    preco DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_category_id FOREIGN KEY(category_id) REFERENCES DIM_CATEGORY(category_id),
    CONSTRAINT fk_seller_id FOREIGN KEY(sk_seller_id) REFERENCES DIM_CUSTOMER_SELLER(sk_seller_id)
);

--DDL TABELA DIM_TEMPO
CREATE TABLE DIM_TEMPO (
    date_id SERIAL PRIMARY KEY,
    dia_ref INT NOT NULL,
    mes_ref INT NOT NULL,
    ano_ref INT NOT NULL,
    dia_semana INT NOT NULL,
    feriado BOOLEAN NOT NULL
);

--DDL TABELA DIM_CATEGORY
CREATE TABLE DIM_CATEGORY (
    category_id SERIAL PRIMARY KEY,
    label VARCHAR(50) NOT NULL,
    subcategory_id INT NOT NULL,
    thirdcategory_id INT NOT NULL,
    fourthcategory_id INT NOT NULL,
    path_navegacao VARCHAR(300) NOT NULL
);