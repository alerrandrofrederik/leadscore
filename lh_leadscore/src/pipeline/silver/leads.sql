-- RF-04, RF-05, RF-06 · Um lead por e-mail (o envio mais recente vence), unido a empresa e histórico.
CREATE OR REFRESH MATERIALIZED VIEW silver.leads (
  CONSTRAINT lead_id_presente  EXPECT (lead_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT email_presente    EXPECT (email IS NOT NULL AND email <> '') ON VIOLATION DROP ROW,
  CONSTRAINT email_formato     EXPECT (email RLIKE '^[^@]+@[^@]+\\.[^@]+$'),
  CONSTRAINT cnpj_valido_ou_vazio EXPECT (cnpj_valido IS NULL OR cnpj_valido),
  CONSTRAINT recebido_em_valido   EXPECT (recebido_em IS NOT NULL)
)
COMMENT 'Leads únicos por e-mail, com perfil da empresa e histórico comercial'
AS
WITH ultimos AS (
  SELECT *
  FROM silver.leads_normalizados
  QUALIFY row_number() OVER (
    PARTITION BY email
    ORDER BY recebido_em DESC NULLS LAST, _ingerido_em DESC, lead_id DESC
  ) = 1
)
SELECT
  l.lead_id,
  l.nome,
  l.email,
  l.telefone,
  l.cnpj,
  l.cnpj_valido,
  l.canal,
  l.campanha,
  l.mensagem,
  l.msg_curta,
  l.recebido_em,
  l.data_arquivo,
  e.razao_social                         AS empresa,
  coalesce(e.porte, 'desconhecido')      AS porte,
  e.segmento,
  e.num_funcionarios,
  e.uf,
  coalesce(h.ja_cliente, false)          AS ja_cliente,
  coalesce(h.oportunidades_ganhas, 0)    AS oportunidades_ganhas,
  coalesce(h.produtos_ganhos, array())   AS produtos_ganhos
FROM ultimos l
LEFT JOIN silver.empresas e
  ON l.cnpj_valido AND e.cnpj = l.cnpj
LEFT JOIN silver.historico_empresa h
  ON l.cnpj_valido AND h.cnpj = l.cnpj;
