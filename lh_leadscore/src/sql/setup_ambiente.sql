-- M0 · T0.2 · Catálogo, schemas e volumes do Lead Score (idempotente).
-- Rodar com: databricks experimental aitools tools query --file src/sql/setup_ambiente.sql --profile leadscore
-- Fica fora do bundle porque, em mode: development, schemas declarados no bundle ganham prefixo dev_<usuário>_.
-- Bloco BEGIN/END: a CLI executa um único statement por arquivo.
BEGIN
  CREATE CATALOG IF NOT EXISTS leadscore COMMENT 'Lead Score · workshop Atlas Software';
  CREATE SCHEMA IF NOT EXISTS leadscore.landing COMMENT 'Arquivos de entrada (Volumes)';
  CREATE SCHEMA IF NOT EXISTS leadscore.bronze  COMMENT 'Dado cru, como veio dos CSVs';
  CREATE SCHEMA IF NOT EXISTS leadscore.silver  COMMENT 'Dado limpo, deduplicado e unido';
  CREATE SCHEMA IF NOT EXISTS leadscore.gold    COMMENT 'IA, Lead Score e Fila do Dia';
  CREATE VOLUME IF NOT EXISTS leadscore.landing.raw      COMMENT 'CSVs diários: leads/, empresas/, historico/';
  CREATE VOLUME IF NOT EXISTS leadscore.landing.gabarito COMMENT 'Gabarito de intenção e entidades (fora do raw)';
END;
