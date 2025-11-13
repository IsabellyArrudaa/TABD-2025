-- CONSULTA 1: Verificar o Gatilho 1 (Notas Médias)
-- Mostra os livros que TÊM uma nota média (ou seja, receberam avaliações)
-- e prova que a coluna 'nota_media' foi preenchida pelo gatilho.
SELECT 
    id, 
    titulo, 
    nota_media
FROM 
    Livros
WHERE 
    nota_media > 0.0
ORDER BY 
    nota_media DESC
LIMIT 10;


-- CONSULTA 2: Verificação CRUZADA do Gatilho 1
-- Compara a 'nota_media' (calculada pelo gatilho) com a média calculada
-- manualmente na hora. Os dois valores devem ser idênticos.
SELECT 
    l.id, 
    l.titulo, 
    l.nota_media AS media_do_gatilho, 
    AVG(a.nota) AS media_calculada_agora
FROM 
    Livros l
JOIN 
    Avaliacoes a ON l.id = a.livro_id
GROUP BY
    l.id, l.titulo, l.nota_media
HAVING
    l.nota_media > 0.0
ORDER BY 
    l.nota_media DESC
LIMIT 10;


-- CONSULTA 3: Verificar o Gatilho 2 (Log de Pedidos)
-- Mostra os registros que foram inseridos AUTOMATICAMENTE
-- na tabela de log pelo gatilho.
SELECT 
    * FROM 
    LogAuditoriaPedidos
ORDER BY 
    log_timestamp DESC
LIMIT 10;

-- CONSULTA 4: Contagem de Verificação
-- O número de linhas em LogAuditoriaPedidos deve ser IGUAL
-- ao número de linhas em Pedidos.
SELECT 
    (SELECT COUNT(*) FROM Pedidos) AS total_pedidos,
    (SELECT COUNT(*) FROM LogAuditoriaPedidos) AS total_logs_pedidos;