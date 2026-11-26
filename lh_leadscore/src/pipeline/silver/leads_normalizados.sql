-- RF-03 · Uma linha por linha da Bronze, com e-mail e CNPJ normalizados.
-- É streaming para alimentar a IA incremental (gold.leads_ia); a deduplicação fica em silver.leads.
CREATE OR REFRESH STREAMING TABLE silver.leads_normalizados
COMMENT 'Leads normalizados (e-mail, CNPJ, mensagem curta), uma linha por envio'
AS SELECT
  lead_id,
  trim(nome)                                              AS nome,
  lower(regexp_replace(email, '\\s', ''))                 AS email,
  email                                                   AS email_original,
  telefone,
  leadscore.silver.cnpj_normalizar(cnpj)                  AS cnpj,
  leadscore.silver.cnpj_valido(cnpj)                      AS cnpj_valido,
  lower(trim(canal))                                      AS canal,
  trim(campanha)                                          AS campanha,
  mensagem,
  coalesce(length(trim(mensagem)), 0) < 5                 AS msg_curta,
  recebido_em,
  to_date(regexp_extract(_arquivo, '(\\d{4}-\\d{2}-\\d{2})', 1)) AS data_arquivo,
  _arquivo,
  _ingerido_em,
  _rescued_data
FROM STREAM(bronze.leads_raw);
