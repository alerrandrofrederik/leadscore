# M0 · Ambiente

**Objetivo:** workspace pronto para receber o pipeline: catálogo, schemas, volumes, dados de apoio e AI Functions validadas.
**Pronto quando:** catálogo, schemas, volumes e CSVs de apoio verificados no workspace (profile `leadscore`). → PRD §4

---

## T0.1 · Apontar o bundle para o catálogo `leadscore`
- Status: [x] concluída
- Requisitos: — · Aceite: —
- Depende de: —
- Arquivos: `databricks.yml`
- Fazer: trocar `catalog: workspace` por `catalog: leadscore` nos targets `dev` e `prod`. Manter `schema` como está (os objetos usam schemas fixos bronze/silver/gold).
- Verificar: `databricks bundle validate --profile leadscore` sem erros.
- Evidência: 2026-11-26 · catalog: leadscore, schema: bronze nos targets dev/prod; variáveis warehouse_id e genie_space_id; bundle validate --strict OK.

## T0.2 · Criar catálogo, schemas e volumes
- Status: [x] concluída
- Requisitos: — · Aceite: —
- Depende de: T0.1
- Arquivos: `resources/leadscore.schemas.yml` (schemas e volumes); catálogo por SQL se não puder ser declarado no bundle
- Fazer: catálogo `leadscore`; schemas `landing`, `bronze`, `silver`, `gold`; volumes `landing.raw` e `landing.gabarito`; pastas `raw/leads/`, `raw/empresas/`, `raw/historico/`.
- Verificar: `databricks schemas list leadscore --profile leadscore` lista os 4 schemas; `databricks volumes list leadscore landing --profile leadscore` lista `raw` e `gabarito`.
- Evidência: 2026-11-26 · src/sql/setup_ambiente.sql (BEGIN/END, idempotente). Schemas e volumes via SQL, fora do bundle: em mode: development o DABs prefixaria os schemas. schemas list: landing, bronze, silver, gold; volumes: raw, gabarito.

## T0.3 · Subir dados de apoio (não os leads)
- Status: [x] concluída
- Requisitos: — · Aceite: —
- Depende de: T0.2
- Arquivos: `data/lead_score_dados/raw/empresas/`, `data/lead_score_dados/raw/historico/`, `data/lead_score_dados/gabarito/`
- Fazer: `databricks fs cp` de empresas → `dbfs:/Volumes/leadscore/landing/raw/empresas/`, oportunidades → `.../raw/historico/`, gabarito → `.../gabarito/`. **Não** subir `leads_2026-11-23.csv` (é ao vivo). Não usar `data/gabarito/` (geração antiga).
- Verificar: `databricks fs ls dbfs:/Volumes/leadscore/landing/raw/empresas/ --profile leadscore` (e historico, gabarito) mostra os arquivos; `raw/leads/` vazio.
- Evidência: 2026-11-26 · empresas_2026-11-23.csv, oportunidades_2026-11-23.csv, gabarito/intencao.csv e entidades.csv nos volumes; raw/leads vazio antes do T1.4.

## T0.4 · Validar AI Functions no workspace
- Status: [x] concluída
- Requisitos: RF-07, RF-08 (risco PRD §3.2) · Aceite: —
- Depende de: —
- Arquivos: `src/sql/verificacao/t0_4_ai_functions.sql`
- Fazer: rodar `ai_classify` e `ai_extract` (versão 2.1, prompts do PRD §2.5) sobre o texto da mensagem herói num SQL warehouse serverless.
- Verificar: classify retorna `compra_imediata`; extract retorna os 6 campos do CA-07. Se falhar, registrar e acionar o plano B (resultado pré-processado).
- Evidência: 2026-11-26 · src/sql/verificacao/t0_4_ai_functions.sql → compra_imediata; Atlas Gestão, 200, dezembro, true, Diretor Financeiro, OmniERP (metadata.version 2.1).

## T0.5 · SQL warehouse e grants
- Status: [x] concluída
- Requisitos: RF-13..16 (pré-requisito) · Aceite: —
- Depende de: T0.2
- Arquivos: `resources/leadscore.app.yml` (grants entram na T4.1), anotar `warehouse_id` como variável do bundle
- Fazer: escolher/criar um SQL warehouse serverless para o app e o Genie; registrar o id em `databricks.yml` (`variables.warehouse_id`).
- Verificar: `databricks warehouses get <id> --profile leadscore` com `enable_serverless_compute: true`.
- Evidência: 2026-11-26 · Serverless Starter Warehouse 4c2bc55088722e76 (variável warehouse_id). Grants do app ficam na T4.1.

---

## Checklist do marco
- [x] T0.1 · [x] T0.2 · [x] T0.3 · [x] T0.4 · [x] T0.5
