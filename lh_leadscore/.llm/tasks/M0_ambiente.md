# M0 · Ambiente

**Objetivo:** workspace pronto para receber o pipeline: catálogo, schemas, volumes, dados de apoio e AI Functions validadas.
**Pronto quando:** catálogo, schemas, volumes e CSVs de apoio verificados no workspace (profile `leadscore`). → PRD §4

---

## T0.1 · Apontar o bundle para o catálogo `leadscore`
- Status: [ ] pendente
- Requisitos: — · Aceite: —
- Depende de: —
- Arquivos: `databricks.yml`
- Fazer: trocar `catalog: workspace` por `catalog: leadscore` nos targets `dev` e `prod`. Manter `schema` como está (os objetos usam schemas fixos bronze/silver/gold).
- Verificar: `databricks bundle validate --profile leadscore` sem erros.
- Evidência:

## T0.2 · Criar catálogo, schemas e volumes
- Status: [ ] pendente
- Requisitos: — · Aceite: —
- Depende de: T0.1
- Arquivos: `resources/leadscore.schemas.yml` (schemas e volumes); catálogo por SQL se não puder ser declarado no bundle
- Fazer: catálogo `leadscore`; schemas `landing`, `bronze`, `silver`, `gold`; volumes `landing.raw` e `landing.gabarito`; pastas `raw/leads/`, `raw/empresas/`, `raw/historico/`.
- Verificar: `databricks schemas list leadscore --profile leadscore` lista os 4 schemas; `databricks volumes list leadscore landing --profile leadscore` lista `raw` e `gabarito`.
- Evidência:

## T0.3 · Subir dados de apoio (não os leads)
- Status: [ ] pendente
- Requisitos: — · Aceite: —
- Depende de: T0.2
- Arquivos: `data/lead_score_dados/raw/empresas/`, `data/lead_score_dados/raw/historico/`, `data/lead_score_dados/gabarito/`
- Fazer: `databricks fs cp` de empresas → `dbfs:/Volumes/leadscore/landing/raw/empresas/`, oportunidades → `.../raw/historico/`, gabarito → `.../gabarito/`. **Não** subir `leads_2026-11-23.csv` (é ao vivo). Não usar `data/gabarito/` (geração antiga).
- Verificar: `databricks fs ls dbfs:/Volumes/leadscore/landing/raw/empresas/ --profile leadscore` (e historico, gabarito) mostra os arquivos; `raw/leads/` vazio.
- Evidência:

## T0.4 · Validar AI Functions no workspace
- Status: [ ] pendente
- Requisitos: RF-07, RF-08 (risco PRD §3.2) · Aceite: —
- Depende de: —
- Arquivos: `src/sql/verificacao/t0_4_ai_functions.sql`
- Fazer: rodar `ai_classify` e `ai_extract` (versão 2.1, prompts do PRD §2.5) sobre o texto da mensagem herói num SQL warehouse serverless.
- Verificar: classify retorna `compra_imediata`; extract retorna os 6 campos do CA-07. Se falhar, registrar e acionar o plano B (resultado pré-processado).
- Evidência:

## T0.5 · SQL warehouse e grants
- Status: [ ] pendente
- Requisitos: RF-13..16 (pré-requisito) · Aceite: —
- Depende de: T0.2
- Arquivos: `resources/leadscore.app.yml` (grants entram na T4.1), anotar `warehouse_id` como variável do bundle
- Fazer: escolher/criar um SQL warehouse serverless para o app e o Genie; registrar o id em `databricks.yml` (`variables.warehouse_id`).
- Verificar: `databricks warehouses get <id> --profile leadscore` com `enable_serverless_compute: true`.
- Evidência:

---

## Checklist do marco
- [ ] T0.1 · [ ] T0.2 · [ ] T0.3 · [ ] T0.4 · [ ] T0.5
