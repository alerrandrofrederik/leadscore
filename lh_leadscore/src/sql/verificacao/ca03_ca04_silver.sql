-- CA-03 · 96 leads, 0 e-mails duplicados, CNPJs convergem, 2 inválidos com cnpj_valido = false.
-- CA-04 · No reenvio que evolui, sobrevive L20261123-0064 (mensagem de compra).
SELECT
  (SELECT count(*) FROM leadscore.silver.leads)                                     AS leads_silver,        -- 96
  (SELECT count(DISTINCT email) FROM leadscore.silver.leads)                        AS emails_distintos,    -- 96
  (SELECT count_if(cnpj_valido = false) FROM leadscore.silver.leads_normalizados)   AS cnpj_invalidos,      -- 2
  (SELECT count(*) FROM leadscore.silver.leads_normalizados
     WHERE cnpj IS NOT NULL AND cnpj NOT RLIKE '^[0-9]{14}$')                       AS cnpj_fora_padrao,    -- 0
  (SELECT count(*) FROM leadscore.silver.leads WHERE cnpj_valido AND empresa IS NULL) AS validos_sem_empresa,
  (SELECT count(*) FROM leadscore.silver.empresas)                                  AS empresas_silver,     -- 121
  (SELECT sum(oportunidades_ganhas) FROM leadscore.silver.historico_empresa)        AS ganhas,              -- 49
  (SELECT count(*) FROM leadscore.silver.leads WHERE lead_id = 'L20261123-0064')    AS reenvio_compra_sobrevive -- 1
