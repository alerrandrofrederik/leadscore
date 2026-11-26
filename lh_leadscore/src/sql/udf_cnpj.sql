-- M2 · T2.1 · Funções SQL de CNPJ (RF-03). Idempotente.
-- Rodar com: databricks experimental aitools tools query --file src/sql/udf_cnpj.sql --profile leadscore
--   cnpj_normalizar('18.451.462/0001-90') = '18451462000190'  (NULL se não tiver 14 dígitos)
--   cnpj_valido(s): NULL se vazio · false se formato ou dígito verificador inválido · true se válido
BEGIN
  CREATE OR REPLACE FUNCTION leadscore.silver.cnpj_normalizar(s STRING)
  RETURNS STRING
  COMMENT 'CNPJ só com dígitos (14) ou NULL'
  RETURN CASE WHEN length(regexp_replace(s, '[^0-9]', '')) = 14 THEN regexp_replace(s, '[^0-9]', '') END;

  CREATE OR REPLACE FUNCTION leadscore.silver.cnpj_dv(base STRING, pesos ARRAY<INT>)
  RETURNS INT
  COMMENT 'Dígito verificador do CNPJ (módulo 11) para a base e os pesos informados'
  RETURN (
    WITH r AS (
      SELECT aggregate(
               sequence(1, size(pesos)), 0,
               (acc, i) -> acc + cast(substr(base, i, 1) AS INT) * element_at(pesos, i)
             ) % 11 AS resto
    )
    SELECT CASE WHEN resto < 2 THEN 0 ELSE 11 - resto END FROM r
  );

  CREATE OR REPLACE FUNCTION leadscore.silver.cnpj_valido(s STRING)
  RETURNS BOOLEAN
  COMMENT 'NULL se vazio; true se o CNPJ tem 14 dígitos e os dígitos verificadores conferem'
  RETURN CASE
    WHEN s IS NULL OR trim(s) = '' THEN NULL
    WHEN leadscore.silver.cnpj_normalizar(s) IS NULL THEN false
    WHEN leadscore.silver.cnpj_normalizar(s) RLIKE '^(\\d)\\1{13}$' THEN false
    ELSE
      leadscore.silver.cnpj_dv(substr(leadscore.silver.cnpj_normalizar(s), 1, 12), array(5,4,3,2,9,8,7,6,5,4,3,2))
        = cast(substr(leadscore.silver.cnpj_normalizar(s), 13, 1) AS INT)
      AND leadscore.silver.cnpj_dv(substr(leadscore.silver.cnpj_normalizar(s), 1, 13), array(6,5,4,3,2,9,8,7,6,5,4,3,2))
        = cast(substr(leadscore.silver.cnpj_normalizar(s), 14, 1) AS INT)
  END;
END;
