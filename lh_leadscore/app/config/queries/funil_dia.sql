-- Visão do Gestor (RF-15): funil recebidos → classificados → na fila → contatados.
-- @param atualizacao STRING = inicial
WITH dia AS (
  SELECT max(data_arquivo) AS data FROM leadscore.gold.leads_classificados
),
fila AS (
  SELECT f.lead_id FROM leadscore.gold.fila_do_dia f JOIN dia d ON f.data = d.data
)
SELECT 1 AS ordem, 'Recebidos' AS etapa, 'Linhas do CSV do dia (Bronze)' AS detalhe,
       (SELECT count(*) FROM leadscore.silver.leads_normalizados n JOIN dia d ON n.data_arquivo = d.data) AS leads
UNION ALL
SELECT 2, 'Classificados', 'Leads únicos com intenção da IA',
       (SELECT count(*) FROM leadscore.gold.leads_classificados c JOIN dia d ON c.data_arquivo = d.data
         WHERE c.intencao IS NOT NULL)
UNION ALL
SELECT 3, 'Na fila', '20 maiores notas · 5 por vendedor',
       (SELECT count(*) FROM fila)
UNION ALL
SELECT 4, 'Contatados', 'Marcados pelos vendedores no app',
       (SELECT count(DISTINCT fc.lead_id) FROM leadscore.gold.feedback_contatos fc
         WHERE fc.lead_id IN (SELECT lead_id FROM fila) AND length(:atualizacao) >= 0)
ORDER BY ordem
