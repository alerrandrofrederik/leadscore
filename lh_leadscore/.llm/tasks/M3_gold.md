# M3 · Gold

**Objetivo:** intenção e entidades pela IA, Lead Score explicável e a Fila do Dia.
**Pronto quando:** CA-05 a CA-09 e CA-12 aprovados. → PRD §2.5, §2.6 (RF-07..12), §2.7, §2.10, §3.1

---

## T3.1 · `gold.leads_ia` (IA incremental)
- Status: [ ] pendente
- Requisitos: RF-07, RF-08 · Aceite: CA-05, CA-06, CA-07, CA-12
- Depende de: T2.2, T0.4
- Arquivos: `src/pipeline/gold/leads_ia.sql`
- Fazer: streaming table `FROM STREAM silver.leads_normalizados`. Quando `msg_curta`: `intencao = 'spam'` e entidades nulas, sem chamar IA. Caso contrário: `ai_classify` e `ai_extract` com rótulos, descrições e schema **literais** do PRD §2.5 e `map('version','2.1')`; extrair `intencao_raw:response[0].value::string` e `entidades_raw:response.<campo>.value`; gravar `ia_versao = '2.1'` e `processado_em`.
- Verificar: ver T3.7.
- Evidência:

## T3.2 · Lead Score e componentes
- Status: [ ] pendente
- Requisitos: RF-09 · Aceite: CA-08, CA-09
- Depende de: T2.4, T3.1
- Arquivos: `src/pipeline/gold/leads_classificados.sql`
- Fazer: componentes conforme PRD §2.7: intenção (100/40/0/0), perfil (porte 100/60/30/20 + 20 se `ja_cliente` com outro produto, máx. 100), sinais (+40 orçamento, +30 prazo, +30 qtd, máx. 100), recência (100 no dia, 50 no seguinte, 0 após 3 dias, relativa a `data_arquivo`). `lead_score = round(0.5*i + 0.25*p + 0.15*s + 0.10*r)`; trava `spam → 0`. `score_componentes` como struct.
- Verificar: todo spam com score 0; lead herói com intenção 100, sinais 100.
- Evidência:

## T3.3 · Motivo e próximo passo por regra
- Status: [ ] pendente
- Requisitos: RF-10 · Aceite: CA-09
- Depende de: T3.2
- Arquivos: `src/pipeline/gold/leads_classificados.sql`
- Fazer: `motivo` concatenando com " · " os sinais presentes (ex.: "Pediu 200 licenças do Atlas Gestão até dezembro · empresa grande"); `proximo_passo` por intenção (`spam` → "Descartar", `suporte` → "Encaminhar ao suporte", compra/avaliando → ação comercial definida aqui). Sem `ai_query`.
- Verificar: lead herói com motivo igual ao exemplo do PRD; nenhum `motivo` nulo para compra_imediata.
- Evidência:

## T3.4 · `gold.leads_classificados`
- Status: [ ] pendente
- Requisitos: RF-12 · Aceite: CA-11
- Depende de: T3.2, T3.3
- Arquivos: `src/pipeline/gold/leads_classificados.sql`
- Fazer: materialized view `silver.leads JOIN gold.leads_ia USING (lead_id)` com exatamente as colunas do PRD §2.10; comentários de tabela/coluna em português (ajudam o Genie).
- Verificar: 96 linhas; `GROUP BY intencao` = 26 compra_imediata · 36 avaliando · 16 suporte · 18 spam (com a IA acertando).
- Evidência:

## T3.5 · `gold.fila_do_dia`
- Status: [ ] pendente
- Requisitos: RF-11 · Aceite: CA-08, CA-09
- Depende de: T3.4
- Arquivos: `src/pipeline/gold/fila_do_dia.sql`
- Fazer: materialized view: excluir spam e suporte, ordenar por `lead_score DESC, recebido_em ASC`, top 20, `posicao` 1..20, `vendedor` por rodízio sobre 4 nomes fixos (`VALUES`, definir os nomes aqui), `data = data_arquivo`.
- Verificar: ver T3.7.
- Evidência:

## T3.6 · `gold.feedback_contatos`
- Status: [ ] pendente
- Requisitos: RF-14 · Aceite: CA-10
- Depende de: T0.2
- Arquivos: `src/sql/feedback_contatos.sql`
- Fazer: `CREATE TABLE IF NOT EXISTS leadscore.gold.feedback_contatos (lead_id STRING, vendedor STRING, contatado_em TIMESTAMP, resultado STRING)`. Fora do pipeline (escrita pelo app).
- Verificar: `DESCRIBE leadscore.gold.feedback_contatos`.
- Evidência:

## T3.7 · Provar CA-05 a CA-09 e CA-12
- Status: [ ] pendente
- Requisitos: RF-07..RF-11 · Aceite: CA-05, CA-06, CA-07, CA-08, CA-09, CA-12
- Depende de: T3.1..T3.5, T0.3
- Arquivos: `src/sql/verificacao/ca05_ca12_gold.sql`, opcional `tests/test_gold.py`
- Verificar:
  - **CA-05:** acurácia de `gold.leads_ia.intencao` vs `read_files('/Volumes/leadscore/landing/gabarito/intencao.csv')` ≥ **85%**.
  - **CA-06:** ≥ **4 de 5** pegadinhas (coluna `pegadinha` do gabarito) corretas.
  - **CA-07:** `L20261123-0089` → Atlas Gestão, 200, dezembro, true, Diretor Financeiro, OmniERP (comparar com `gabarito/entidades.csv`).
  - **CA-08:** `count_if(intencao IN ('spam','suporte'))` na fila = 0.
  - **CA-09:** 20 linhas, 5 por vendedor, ordenadas por score, `score_componentes` sem nulos, herói entre as primeiras posições; 6 compra_imediata fora da fila.
  - **CA-12:** rodar o pipeline de novo sem arquivo novo → `gold.leads_ia` sem linhas novas (event log: 0 linhas processadas no fluxo).
- Evidência:

---

## Checklist do marco
- [ ] T3.1 · [ ] T3.2 · [ ] T3.3 · [ ] T3.4 · [ ] T3.5 · [ ] T3.6 · [ ] T3.7
- [ ] CA-05 · [ ] CA-06 · [ ] CA-07 · [ ] CA-08 · [ ] CA-09 · [ ] CA-12
