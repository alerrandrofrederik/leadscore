-- RF-01, RF-02 · Histórico de oportunidades exportado do CRM, como veio.
CREATE OR REFRESH STREAMING TABLE bronze.oportunidades_raw
COMMENT 'Oportunidades cruas do Volume raw/historico (Auto Loader)'
AS SELECT
  *,
  _metadata.file_path  AS _arquivo,
  current_timestamp()  AS _ingerido_em
FROM STREAM read_files(
  '${volume_raw}/historico/',
  format => 'csv',
  header => true,
  schemaHints => 'oportunidade_id STRING, cnpj STRING, valor DOUBLE, data DATE',
  rescuedDataColumn => '_rescued_data'
);
