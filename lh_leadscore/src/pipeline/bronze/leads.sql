-- RF-01, RF-02 · Leads como vieram do CSV, cada arquivo lido uma única vez (Auto Loader).
-- Datas inválidas em recebido_em ficam nulas e o valor original vai para _rescued_data.
CREATE OR REFRESH STREAMING TABLE bronze.leads_raw
COMMENT 'Leads crus do Volume raw/leads (Auto Loader)'
AS SELECT
  *,
  _metadata.file_path  AS _arquivo,
  current_timestamp()  AS _ingerido_em
FROM STREAM read_files(
  '${volume_raw}/leads/',
  format => 'csv',
  header => true,
  multiLine => true,
  schemaHints => 'lead_id STRING, telefone STRING, cnpj STRING, recebido_em TIMESTAMP',
  rescuedDataColumn => '_rescued_data'
);
