-- RF-03, RF-05 · Empresas com CNPJ normalizado, uma linha por CNPJ (a carga mais recente vence).
CREATE OR REFRESH MATERIALIZED VIEW silver.empresas (
  CONSTRAINT cnpj_presente EXPECT (cnpj IS NOT NULL) ON VIOLATION DROP ROW
)
COMMENT 'Base cadastral de empresas, uma linha por CNPJ'
AS SELECT
  leadscore.silver.cnpj_normalizar(cnpj) AS cnpj,
  trim(razao_social)                     AS razao_social,
  lower(trim(porte))                     AS porte,
  trim(segmento)                         AS segmento,
  num_funcionarios,
  upper(trim(uf))                        AS uf
FROM bronze.empresas_raw
QUALIFY row_number() OVER (PARTITION BY leadscore.silver.cnpj_normalizar(cnpj) ORDER BY _ingerido_em DESC) = 1;
