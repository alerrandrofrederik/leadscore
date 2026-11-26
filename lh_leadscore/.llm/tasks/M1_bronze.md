# M1 · Bronze

**Objetivo:** ingerir os CSVs do Volume `raw` com Auto Loader, cada arquivo uma vez, guardando o dado como veio.
**Pronto quando:** CA-01 e CA-02 aprovados. → PRD §2.6 (RF-01, RF-02), §3.1

---

## T1.1 · Declarar o pipeline Lakeflow
- Status: [ ] pendente
- Requisitos: RF-01 · Aceite: —
- Depende de: T0.2
- Arquivos: `resources/leadscore.pipeline.yml`
- Fazer: pipeline serverless, `catalog: ${var.catalog}`, `schema: bronze` como padrão, `libraries` apontando para `src/pipeline/**`. Nome único: `lh_leadscore_pipeline`.
- Verificar: `databricks bundle validate --profile leadscore` e `databricks bundle deploy --profile leadscore` criam o pipeline.
- Evidência:

## T1.2 · `bronze.leads_raw`
- Status: [ ] pendente
- Requisitos: RF-01, RF-02 · Aceite: CA-01, CA-02
- Depende de: T1.1
- Arquivos: `src/pipeline/bronze/leads.sql`
- Fazer: streaming table com `STREAM read_files('/Volumes/leadscore/landing/raw/leads/', format => 'csv', header => true, schemaHints => 'recebido_em TIMESTAMP')`; colunas `_arquivo` (`_metadata.file_path`) e `_ingerido_em`; manter `_rescued_data`. Sem transformação de conteúdo.
- Verificar: ver T1.4.
- Evidência:

## T1.3 · `bronze.empresas_raw` e `bronze.oportunidades_raw`
- Status: [ ] pendente
- Requisitos: RF-01, RF-02 · Aceite: —
- Depende de: T1.1
- Arquivos: `src/pipeline/bronze/empresas.sql`, `src/pipeline/bronze/oportunidades.sql`
- Fazer: mesmo padrão da T1.2 para `raw/empresas/` e `raw/historico/`.
- Verificar: após rodar, `SELECT count(*)` = 121 empresas e 119 oportunidades.
- Evidência:

## T1.4 · Provar CA-01 e CA-02
- Status: [ ] pendente
- Requisitos: RF-01, RF-02 · Aceite: CA-01, CA-02
- Depende de: T1.2, T1.3
- Arquivos: `src/sql/verificacao/ca01_ca02_bronze.sql`
- Fazer: subir `leads_2026-11-23.csv` para `raw/leads/`, rodar o pipeline, rodar de novo sem arquivo novo.
- Verificar:
  - `SELECT count(*) FROM leadscore.bronze.leads_raw` = **100** após a 1ª execução e continua 100 após a 2ª (0 novos).
  - `SELECT count(*) FROM leadscore.bronze.leads_raw WHERE _rescued_data IS NOT NULL` = **2**, pipeline com status `COMPLETED`.
- Evidência:

---

## Checklist do marco
- [ ] T1.1 · [ ] T1.2 · [ ] T1.3 · [ ] T1.4
- [ ] CA-01 · [ ] CA-02
