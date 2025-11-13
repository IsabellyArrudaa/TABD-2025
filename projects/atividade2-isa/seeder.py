# !/usr/bin/env python3

# Example seeder script

# ----------------------------------------------------------------------------------------------
# This script uses the Seeder class to populate a PostgreSQL database with
# sample data.
# ----------------------------------------------------------------------------------------------

# DO NOT CHANGE THE IMPORTS BELOW
import os
import site
import random 

site.addsitedir(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from lib import fake, Seeder
# DO NOT CHANGE THE IMPORTS ABOVE

# ----------------------------------------------------------------------------------------------
# CHANGE THE PARAMETERS AND VARIABLES BELOW TO MATCH YOUR DATABASE SCHEMA
# ----------------------------------------------------------------------------------------------

db_host = "localhost"
db_port = 5432
db_name = "tabd"

# ----------------------------------------------------------------------------------------------
# Seeder must be initialized with the correct DB connection info before you can use it on seeding
# ----------------------------------------------------------------------------------------------
seeder = Seeder(db_host, db_port, db_name)

schema = {
    "editoras": { "nome": lambda: fake.unique_except(seeder.select("editoras", "nome", cache=False)).company() },
    "generos": { "nome": lambda: fake.unique_except(seeder.select("generos", "nome", cache=False)).random_element(elements=('Ficção Científica', 'Fantasia', 'Romance', 'Terror', 'Técnico', 'Biografia')) },
    "autores": { "nome": lambda: fake.name() },
    "clientes": { "nome": lambda: fake.name(), "email": lambda: fake.unique_except(seeder.select("clientes", "email", cache=False)).email(), "data_cadastro": lambda: fake.date_time_this_decade() },
    "promocoes": { "descricao": lambda: fake.sentence(nb_words=4), "percentual_desconto": lambda: round(fake.random_element(elements=(5, 10, 15, 20, 25))), "data_inicio": lambda: fake.past_date(), "data_fim": lambda: fake.future_date() },
    "livros": { "titulo": lambda: fake.catch_phrase(), "isbn": lambda: fake.unique_except(seeder.select("livros", "isbn", cache=False)).isbn13(), "ano_publicacao": lambda: int(fake.year()), "editora_id": lambda: random.choice([int(id) for id in seeder.select("editoras", "id")]) },
    "pedidos": { "cliente_id": lambda: random.choice([int(id) for id in seeder.select("clientes", "id")]), "data_pedido": lambda: fake.date_time_this_year(), "status": lambda: fake.random_element(elements=('processando', 'pago', 'enviado', 'entregue', 'cancelado')) },
    "itenspedido": {
        "pedido_id": lambda: random.choice([int(id) for id in seeder.select("pedidos", "id")]),
        "livro_id": lambda: random.choice([int(id) for id in seeder.select("livros", "id")]),
        "quantidade": lambda: random.randint(1, 3),
        "preco_unitario": lambda: round(random.uniform(20.0, 120.0), 2),
        "promocao_id": lambda: random.choice([int(id) for id in seeder.select("promocoes", "id")]) if random.random() < 0.3 else None
    },
    "avaliacoes": { "cliente_id": lambda: random.choice([int(id) for id in seeder.select("clientes", "id")]), "livro_id": lambda: random.choice([int(id) for id in seeder.select("livros", "id")]), "nota": lambda: random.randint(1, 5), "comentario": lambda: fake.sentence(nb_words=15), "data_avaliacao": lambda: fake.date_time_this_year() },
}

rows = {
    "editoras": 20, "generos": 6, "autores": 150, "clientes": 300, "promocoes": 50,
    "livros": 500, "pedidos": 1500, "itenspedido": 4000, "avaliacoes": 5000,
}

# ----------------------------------------------------------------------------------------------
# --- PARTE 1: Popular as Tabelas Principais ---
print("--- PARTE 1: Populando tabelas principais (livros, autores, clientes, etc.) ---")
seeder.seed(schema, rows)
print("--- PARTE 1: Concluída ---")

# --- PARTE 2: Lógica Especial para Garantir Pares Únicos ---
# !! ESTA PARTE SÓ FUNCIONA DEPOIS QUE A PARTE 1 RODOU !!
print("\n--- PARTE 2: Gerando e inserindo pares únicos para tabelas de junção... ---")

# Pega os IDs que já foram inseridos
book_ids = seeder.select("livros", "id")
author_ids = seeder.select("autores", "id")
genre_ids = seeder.select("generos", "id")

# Lógica para livro_autor
num_livro_autor = 700
livro_autor_pairs = set()
while len(livro_autor_pairs) < num_livro_autor:
    pair = (random.choice(book_ids), random.choice(author_ids))
    livro_autor_pairs.add(pair)

# Lógica para livro_genero
num_livro_genero = 800
livro_genero_pairs = set()
while len(livro_genero_pairs) < num_livro_genero:
    pair = (random.choice(book_ids), random.choice(genre_ids))
    livro_genero_pairs.add(pair)

# Insere os dados de forma eficiente
with seeder.conn.cursor() as cur:
    cur.executemany("INSERT INTO livro_autor (livro_id, autor_id) VALUES (%s, %s)", list(livro_autor_pairs))
    print(f"! {len(livro_autor_pairs)} linhas inseridas em livro_autor")
    
    cur.executemany("INSERT INTO livro_genero (livro_id, genero_id) VALUES (%s, %s)", list(livro_genero_pairs))
    print(f"! {len(livro_genero_pairs)} linhas inseridas em livro_genero")

seeder.conn.commit()
print("--- PARTE 2: Concluída ---")
# --- Fim da Parte 2 ---

print("Done.")
