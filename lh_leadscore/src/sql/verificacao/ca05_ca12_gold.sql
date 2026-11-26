-- CA-05 a CA-09 · Qualidade da IA, travas do score e Fila do Dia.
-- Gabarito em /Volumes/leadscore/landing/gabarito/ (uma linha por envio, inclusive duplicados).
WITH gab AS (
  SELECT lead_id, intencao_esperada, pegadinha
  FROM read_files('/Volumes/leadscore/landing/gabarito/intencao.csv', format => 'csv', header => true)
),
cmp AS (
  SELECT g.lead_id, g.intencao_esperada, g.pegadinha, ia.intencao, (g.intencao_esperada = ia.intencao) AS acertou
  FROM gab g JOIN leadscore.gold.leads_ia ia USING (lead_id)
),
fila AS (SELECT * FROM leadscore.gold.fila_do_dia)
SELECT
  (SELECT count(*) FROM cmp)                                                   AS linhas_comparadas,     -- 100
  (SELECT round(100 * avg(cast(acertou AS INT)), 1) FROM cmp)                  AS acuracia_pct,          -- CA-05 ≥ 85
  (SELECT count_if(acertou) FROM cmp WHERE pegadinha IS NOT NULL AND pegadinha <> '') AS pegadinhas_ok,  -- CA-06 ≥ 4
  (SELECT count(*) FROM cmp WHERE pegadinha IS NOT NULL AND pegadinha <> '')   AS pegadinhas_total,      -- 5
  (SELECT count_if(intencao IN ('spam', 'suporte')) FROM fila)                 AS spam_suporte_na_fila,  -- CA-08 = 0
  (SELECT count(*) FROM fila)                                                  AS fila_total,            -- 20
  (SELECT count(DISTINCT vendedor) FROM fila)                                  AS vendedores,            -- 4
  (SELECT max(n) FROM (SELECT count(*) n FROM fila GROUP BY vendedor))         AS max_por_vendedor,      -- 5
  (SELECT min(n) FROM (SELECT count(*) n FROM fila GROUP BY vendedor))         AS min_por_vendedor,      -- 5
  (SELECT count_if(score_componentes.intencao IS NULL OR score_componentes.perfil IS NULL
                OR score_componentes.sinais IS NULL OR score_componentes.recencia IS NULL) FROM fila) AS componentes_nulos, -- 0
  (SELECT posicao FROM fila WHERE lead_id = 'L20261123-0089')                  AS posicao_heroi,         -- topo
  (SELECT count(*) FROM leadscore.gold.leads_classificados WHERE intencao = 'compra_imediata') AS compra_imediata, -- 26
  (SELECT count(*) FROM leadscore.gold.leads_classificados c WHERE intencao = 'compra_imediata'
     AND lead_id NOT IN (SELECT lead_id FROM fila))                            AS compra_fora_da_fila    -- 6
