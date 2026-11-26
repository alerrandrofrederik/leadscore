-- Visão do Gestor (RF-15): KPIs do dia mais recente.
-- :atualizacao só entra na chave de cache (o cliente renova a cada minuto e a cada contato).
-- @param atualizacao STRING = inicial
WITH dia AS (
  SELECT max(data_arquivo) AS data FROM leadscore.gold.leads_classificados
),
lc AS (
  SELECT c.* FROM leadscore.gold.leads_classificados c JOIN dia d ON c.data_arquivo = d.data
),
fila AS (
  SELECT f.lead_id FROM leadscore.gold.fila_do_dia f JOIN dia d ON f.data = d.data
),
gab AS (
  SELECT lead_id, intencao_esperada
  FROM read_files('/Volumes/leadscore/landing/gabarito/intencao.csv', format => 'csv', header => true)
),
ia AS (
  SELECT ia.lead_id, ia.intencao, g.intencao_esperada
  FROM leadscore.gold.leads_ia ia
  JOIN leadscore.silver.leads_normalizados n USING (lead_id)
  JOIN dia d ON n.data_arquivo = d.data
  LEFT JOIN gab g USING (lead_id)
)
SELECT
  (SELECT cast(data AS STRING) FROM dia)                                                  AS data,
  (SELECT count(*) FROM leadscore.silver.leads_normalizados n JOIN dia d ON n.data_arquivo = d.data) AS recebidos,
  (SELECT count(*) FROM lc)                                                               AS unicos,
  (SELECT count(*) FROM lc WHERE intencao IS NOT NULL)                                    AS classificados,
  (SELECT count(*) FROM fila)                                                             AS na_fila,
  (SELECT count(DISTINCT fc.lead_id) FROM leadscore.gold.feedback_contatos fc
     WHERE fc.lead_id IN (SELECT lead_id FROM fila) AND length(:atualizacao) >= 0)        AS contatados,
  (SELECT count(*) FROM lc WHERE intencao = 'compra_imediata')                            AS compra_imediata,
  (SELECT count(*) FROM lc WHERE intencao = 'compra_imediata'
     AND lead_id NOT IN (SELECT lead_id FROM fila))                                       AS compra_fora_fila,
  (SELECT round(100 * avg(CASE WHEN intencao = intencao_esperada THEN 1.0 ELSE 0.0 END), 1)
     FROM ia WHERE intencao_esperada IS NOT NULL)                                         AS acuracia_ia_pct,
  (SELECT cast(max(processado_em) AS STRING) FROM lc)                                     AS processado_em
