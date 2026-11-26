-- CA-01 · 100 leads na Bronze (e continua 100 após reexecução sem arquivo novo).
-- CA-02 · 2 datas malformadas em _rescued_data, recebido_em nulo.
SELECT
  (SELECT count(*) FROM leadscore.bronze.leads_raw)                                  AS leads_bronze,           -- 100
  (SELECT count(DISTINCT _arquivo) FROM leadscore.bronze.leads_raw)                  AS arquivos_leads,         -- 1
  (SELECT count(*) FROM leadscore.bronze.leads_raw WHERE _rescued_data IS NOT NULL)  AS leads_rescued,          -- 2
  (SELECT count(*) FROM leadscore.bronze.leads_raw WHERE recebido_em IS NULL)        AS recebido_em_nulo,       -- 2
  (SELECT count(*) FROM leadscore.bronze.empresas_raw)                               AS empresas_bronze,        -- 121
  (SELECT count(*) FROM leadscore.bronze.oportunidades_raw)                          AS oportunidades_bronze    -- 119
