-- RF-01, RF-02 · Base cadastral de empresas como veio do CSV.
CREATE OR REFRESH STREAMING TABLE bronze.empresas_raw
COMMENT 'Empresas cruas do Volume raw/empresas (Auto Loader)'
AS SELECT
  *,
  _metadata.file_path  AS _arquivo,
  current_timestamp()  AS _ingerido_em
FROM STREAM read_files(
  '${volume_raw}/empresas/',
  format => 'csv',
  header => true,
  schemaHints => 'cnpj STRING, num_funcionarios INT',
  rescuedDataColumn => '_rescued_data'
);
