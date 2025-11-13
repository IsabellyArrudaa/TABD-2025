-- Remove tabelas antigas se existirem, na ordem correta
DROP TABLE IF EXISTS Avaliacoes, ItensPedido, Pedidos, Promocoes, Livro_Autor, Livro_Genero, Livros, Autores, Generos, Editoras, Clientes, LogAuditoriaPedidos CASCADE;

-- === TABELAS PRINCIPAIS (Seu esquema) ===

CREATE TABLE Clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    data_cadastro TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE Editoras (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE Generos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE Autores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL
);

CREATE TABLE Livros (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    isbn VARCHAR(20) UNIQUE,
    ano_publicacao INT,
    editora_id INT REFERENCES Editoras(id),
    -- !! MODIFICAÇÃO 1: Coluna para ser atualizada pelo Gatilho 1
    nota_media DECIMAL(3, 2) DEFAULT 0.0
);

CREATE TABLE Livro_Autor (
    livro_id INT REFERENCES Livros(id) ON DELETE CASCADE,
    autor_id INT REFERENCES Autores(id) ON DELETE CASCADE,
    PRIMARY KEY (livro_id, autor_id)
);

CREATE TABLE Livro_Genero (
    livro_id INT REFERENCES Livros(id) ON DELETE CASCADE,
    genero_id INT REFERENCES Generos(id) ON DELETE CASCADE,
    PRIMARY KEY (livro_id, genero_id)
);

CREATE TABLE Promocoes (
    id SERIAL PRIMARY KEY,
    descricao VARCHAR(255),
    percentual_desconto DECIMAL(5, 2) NOT NULL,
    data_inicio DATE,
    data_fim DATE
);

CREATE TABLE Pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES Clientes(id),
    data_pedido TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(50) -- Ex: 'processando', 'pago', 'enviado'
);

CREATE TABLE ItensPedido (
    id SERIAL PRIMARY KEY,
    pedido_id INT REFERENCES Pedidos(id),
    livro_id INT REFERENCES Livros(id),
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10, 2) NOT NULL, -- Preço no momento da compra
    promocao_id INT REFERENCES Promocoes(id) NULL -- Promoção aplicada a este item
);

CREATE TABLE Avaliacoes (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES Clientes(id),
    livro_id INT REFERENCES Livros(id),
    nota INT CHECK (nota >= 1 AND nota <= 5),
    comentario TEXT,
    data_avaliacao TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- !! MODIFICAÇÃO 2: Nova tabela para o Gatilho 2
CREATE TABLE LogAuditoriaPedidos (
    log_id SERIAL PRIMARY KEY,
    pedido_id INT,
    cliente_id INT,
    log_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    acao VARCHAR(100)
);


-- ======= GATILHO 1: Atualizar Nota Média do Livro ===

-- 1.A: A FUNÇÃO (O que fazer)
CREATE OR REPLACE FUNCTION atualizar_nota_media_livro()
RETURNS TRIGGER AS $$
BEGIN
    -- 'NEW' refere-se à linha que acabou de ser INSERIDA em 'Avaliacoes'
    UPDATE Livros
    SET nota_media = (SELECT AVG(nota) 
                      FROM Avaliacoes 
                      WHERE livro_id = NEW.livro_id)
    WHERE id = NEW.livro_id;
    
    RETURN NEW; -- Necessário para triggers AFTER
END;
$$ LANGUAGE plpgsql;

-- 1.B: O GATILHO (Quando fazer)
CREATE TRIGGER trg_depois_inserir_avaliacao
AFTER INSERT ON Avaliacoes
FOR EACH ROW
EXECUTE FUNCTION atualizar_nota_media_livro();


-- === GATILHO 2: Logar Novos Pedidos ===

-- 2.A: A FUNÇÃO
CREATE OR REPLACE FUNCTION logar_novo_pedido()
RETURNS TRIGGER AS $$
BEGIN
    -- 'NEW' refere-se à linha que acabou de ser INSERIDA em 'Pedidos'
    INSERT INTO LogAuditoriaPedidos (pedido_id, cliente_id, acao)
    VALUES (NEW.id, NEW.cliente_id, 'Novo pedido criado');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2.B: O GATILHO
CREATE TRIGGER trg_depois_inserir_pedido
AFTER INSERT ON Pedidos
FOR EACH ROW
EXECUTE FUNCTION logar_novo_pedido();