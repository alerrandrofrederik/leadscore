-- Visão do Gestor / Marketing (RF-15, US-05): leads do dia por canal e intenção.
-- @param atualizacao STRING = inicial
WITH dia AS (
  SELECT max(data_arquivo) AS data FROM leadscore.gold.leads_classificados
)
SELECT
  CASE canal
    WHEN 'indicacao'  THEN 'Indicação'
    WHEN 'linkedin'   THEN 'LinkedIn'
    WHEN 'google_ads' THEN 'Google Ads'
    WHEN 'evento'     THEN 'Evento'
    WHEN 'site'       THEN 'Site'
    ELSE coalesce(canal, 'Sem canal')
  END AS canal,
  count_if(intencao = 'compra_imediata') AS compra_imediata,
  count_if(intencao = 'avaliando')       AS avaliando,
  count_if(intencao = 'suporte')         AS suporte,
  count_if(intencao = 'spam')            AS spam
FROM leadscore.gold.leads_classificados c
JOIN dia d ON c.data_arquivo = d.data
WHERE length(:atualizacao) >= 0
GROUP BY 1
ORDER BY compra_imediata DESC, canal
