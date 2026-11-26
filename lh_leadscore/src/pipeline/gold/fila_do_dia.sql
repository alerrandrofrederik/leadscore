-- RF-11 · Os 20 leads de maior score do dia, 5 por vendedor (rodízio pela posição).
-- spam e suporte nunca entram (CA-08). Empate: quem chegou antes vem primeiro.
CREATE OR REFRESH MATERIALIZED VIEW gold.fila_do_dia
COMMENT 'Fila do Dia: 20 leads priorizados pelo Lead Score, distribuídos entre os 4 vendedores'
AS
WITH vendedores AS (
  SELECT * FROM VALUES (0, 'Ana'), (1, 'Bruno'), (2, 'Carla'), (3, 'Diego') AS v(idx, vendedor)
),
dia AS (
  SELECT max(data_arquivo) AS data FROM gold.leads_classificados
),
ranking AS (
  SELECT
    c.*,
    row_number() OVER (ORDER BY c.lead_score DESC, c.recebido_em ASC NULLS LAST, c.lead_id) AS posicao
  FROM gold.leads_classificados c
  JOIN dia d ON c.data_arquivo = d.data
  WHERE c.intencao NOT IN ('spam', 'suporte')
)
SELECT
  r.data_arquivo AS data,
  cast(r.posicao AS INT) AS posicao,
  v.vendedor,
  r.* EXCEPT (posicao, data_arquivo)
FROM ranking r
JOIN vendedores v ON v.idx = (r.posicao - 1) % 4
WHERE r.posicao <= 20;
