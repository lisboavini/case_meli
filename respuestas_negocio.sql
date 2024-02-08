-- ##############################################################
-- A primeira parte do arquivo contém as querys realizadas na modelagem 
-- star-schema (fato e dimensão) analítica para gerar indicadores/relatórios
-- de vendas de acordo com a perspectiva pedida.

-- A segunda parte do arquivo responde ao item 3 pedido que se trata da
-- criação de uma tabela de fechamento a partir do status/preço e atualização
-- na tabela Item... Este é um comportamento transacional, não faz sentido ser
-- endereçado dentro do modelo star-schema e sim criar as FUNCTIONS e PROCEDURES
-- diretamente no que corresponde ao transacional.
-- ##############################################################

-- Query 1) Listar usuários que fazem aniversário hoje cujo número de
-- vendas em janeiro de 2020 é superior a 1500.
SELECT
    s.username AS Usuario,
    SUM(o.total_qtd_vendas) AS NumeroVendasJaneiro2020
FROM
    (SELECT 
        sk_seller_id, 
        SUM(total_qtd_vendas) AS total_qtd_vendas 
    FROM 
        FATO_ORDER 
    JOIN 
        DIM_TEMPO ON FATO_ORDER.date_id = DIM_TEMPO.date_id
    WHERE 
        DIM_TEMPO.mes_ref = 1 AND
        DIM_TEMPO.ano_ref = 2020
    GROUP BY 
        sk_seller_id) o
JOIN
    DIM_SELLER s ON o.sk_seller_id = s.sk_seller_id
WHERE
    DAY(s.data_nasc) = DAY(CURRENT_DATE()) AND
    MONTH(s.data_nasc) = MONTH(CURRENT_DATE())
HAVING
    SUM(o.numero_vendas) > 1500
GROUP BY
    s.username

-- Query 2) Para cada mês de 2020, são solicitados os 5 principais usuários 
-- que mais venderam ($) na categoria Celulares. O mês e o ano de análise, 
-- nome e sobrenome do vendedor, número de vendas realizadas, número de produtos 
-- vendidos e o valor total transacionado são necessários.
WITH VendasCelulares AS (
    SELECT
        o.sk_seller_id,
        MONTH(t.mes_ref) AS Mes,
        YEAR(t.ano_ref) AS Ano,
        SUM(o.valor_vendas) AS ValorTotalVendasCelulares,
        COUNT(o.total_qtd_vendas) AS NumeroVendas,
        SUM(o.total_qtd_items_vendas) AS NumeroProdutosVendidos
    FROM
        FATO_ORDER o
    JOIN
        DIM_TEMPO t ON o.date_id = t.date_id
    JOIN
        DIM_CATEGORY c ON o.category_id = c.category_id
    WHERE
        c.label = 'Celulares' AND
        YEAR(t.ano_ref) = 2020
    GROUP BY
        o.sk_seller_id, Mes, Ano
),
RankUsuarios AS (
    SELECT
        sk_seller_id,
        Mes,
        Ano,
        ROW_NUMBER() OVER (PARTITION BY Mes, Ano ORDER BY ValorTotalVendasCelulares DESC) AS RankVendas
    FROM
        VendasCelulares
)
SELECT
    r.Mes,
    r.Ano,
    cs.nome AS NomeVendedor,
    cs.sobrenome AS SobrenomeVendedor,
    v.NumeroVendas,
    v.NumeroProdutosVendidos,
    v.ValorTotalVendasCelulares
FROM
    RankUsuarios r
JOIN
    VendasCelulares v ON r.sk_seller_id = v.sk_seller_id AND r.Mes = v.Mes AND r.Ano = v.Ano
JOIN
    DIM_CUSTOMER_SELLER cs ON v.sk_seller_id = cs.sk_seller_id
WHERE
    r.RankVendas <= 5
ORDER BY
    r.Ano, r.Mes, r.RankVendas

-- ##############################################################
-- Query 3) É solicitado preencher uma nova tabela com o preço e o status 
-- dos Itens no final do dia. Tenha em mente que ele deve ser reprocessável. 
-- Vale ressaltar que na tabela Item, teremos apenas o último estado informado 
-- pela PK definida. (Pode  ser resolvido via StoredProcedure)

-- II. PROCEDURE PARA ATUALIZAR STATUS NA TABELA ITEM
CREATE OR REPLACE FUNCTION PreencherTabelaFimDia() RETURNS VOID AS $$
DECLARE
    -- Declaração de variáveis locais
    registro RECORD;
BEGIN
    -- Deletar dados antigos da tabela de fechamento do dia, se houver
    DELETE FROM FechamentoDia;

    -- Loop pelos itens
    FOR registro IN
        SELECT DISTINCT ON (fk_item_id) * 
        FROM Item
        ORDER BY fk_item_id, data_update DESC
    LOOP
        -- Inserir na tabela de fechamento do dia
        INSERT INTO FechamentoDia (fk_item_id, fk_preco, fk_seller_id, fk_category_id, qtd_vendida, qtd_disponivel, flag_fechamento, data_inclusao, data_update)
        VALUES (registro.item_id, registro.preco, registro.fk_seller_id, registro.fk_category_id, 0, registro.qtd_disponivel, registro.flag_status, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    END LOOP;
END;
$$ LANGUAGE plpgsql;