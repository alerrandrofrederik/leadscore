-- RF-05 · Histórico comercial agregado por empresa (base do perfil e do bônus de cross-sell).
CREATE OR REFRESH MATERIALIZED VIEW silver.historico_empresa
COMMENT 'Oportunidades agregadas por CNPJ: ganhas, ja_cliente e produtos já comprados'
AS SELECT
  leadscore.silver.cnpj_normalizar(cnpj)                              AS cnpj,
  count(*)                                                            AS oportunidades,
  count_if(lower(status) = 'ganha')                                   AS oportunidades_ganhas,
  count_if(lower(status) = 'ganha') > 0                               AS ja_cliente,
  array_distinct(collect_list(CASE WHEN lower(status) = 'ganha' THEN produto END)) AS produtos_ganhos
FROM bronze.oportunidades_raw
WHERE leadscore.silver.cnpj_normalizar(cnpj) IS NOT NULL
GROUP BY leadscore.silver.cnpj_normalizar(cnpj);
