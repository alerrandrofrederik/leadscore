# M1 · Bronze

**Objetivo:** ingerir os CSVs do Volume `raw` com Auto Loader, cada arquivo uma vez, guardando o dado como veio.
**Pronto quando:** CA-01 e CA-02 aprovados. → PRD §2.6 (RF-01, RF-02), §3.1

---

## T1.1 · Declarar o pipeline Lakeflow
- Status: [x] concluída
- Requisitos: RF-01 · Aceite: —
- Depende de: T0.2
- Arquivos: `resources/leadscore.pipeline.yml`
- Fazer: pipeline serverless, `catalog: ${var.catalog}`, `schema: bronze` como padrão, `libraries` apontando para `src/pipeline/**`. Nome único: `lh_leadscore_pipeline`.
- Verificar: `databricks bundle validate --profile leadscore` e `databricks bundle deploy --profile leadscore` criam o pipeline.
- Evidência: 2026-11-26 · resources/leadscore.pipeline.yml (serverless, lh_leadscore_pipeline) e resources/leadscore.job.yml (refresh 7h); deploy OK.

## T1.2 · `bronze.leads_raw`
- Status: [x] concluída
- Requisitos: RF-01, RF-02 · Aceite: CA-01, CA-02
- Depende de: T1.1
- Arquivos: `src/pipeline/bronze/leads.sql`
- Fazer: streaming table com `STREAM read_files('/Volumes/leadscore/landing/raw/leads/', format => 'csv', header => true, schemaHints => 'recebido_em TIMESTAMP')`; colunas `_arquivo` (`_metadata.file_path`) e `_ingerido_em`; manter `_rescued_data`. Sem transformação de conteúdo.
- Verificar: ver T1.4.
- Evidência: 2026-11-26 · src/pipeline/bronze/leads.sql com schemaHints e rescuedDataColumn; ver T1.4.

## T1.3 · `bronze.empresas_raw` e `bronze.oportunidades_raw`
- Status: [x] concluída
- Requisitos: RF-01, RF-02 · Aceite: —
- Depende de: T1.1
- Arquivos: `src/pipeline/bronze/empresas.sql`, `src/pipeline/bronze/oportunidades.sql`
- Fazer: mesmo padrão da T1.2 para `raw/empresas/` e `raw/historico/`.
- Verificar: após rodar, `SELECT count(*)` = 121 empresas e 119 oportunidades.
- Evidência: 2026-11-26 · empresas_raw = 121, oportunidades_raw = 119.

## T1.4 · Provar CA-01 e CA-02
- Status: [x] concluída
- Requisitos: RF-01, RF-02 · Aceite: CA-01, CA-02
- Depende de: T1.2, T1.3
- Arquivos: `src/sql/verificacao/ca01_ca02_bronze.sql`
- Fazer: subir `leads_2026-11-23.csv` para `raw/leads/`, rodar o pipeline, rodar de novo sem arquivo novo.
- Verificar:
  - `SELECT count(*) FROM leadscore.bronze.leads_raw` = **100** após a 1ª execução e continua 100 após a 2ª (0 novos).
  - `SELECT count(*) FROM leadscore.bronze.leads_raw WHERE _rescued_data IS NOT NULL` = **2**, pipeline com status `COMPLETED`.
- Evidência: 2026-11-26 · src/sql/verificacao/ca01_ca02_bronze.sql: leads_raw = 100 (update dd84da), continua 100 após a reexecução (update 1bf538). _rescued_data = 2 (L20261123-0032 '17/13/2026 25:61', L20261123-0044 'ontem à tarde'), pipeline COMPLETED.

---

## Checklist do marco
- [x] T1.1 · [x] T1.2 · [x] T1.3 · [x] T1.4
- [x] CA-01 · [x] CA-02
