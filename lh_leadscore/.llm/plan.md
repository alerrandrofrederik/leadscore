# Plan · como construir

Decisões técnicas que as tarefas seguem. Mudanças aqui precisam ser coerentes com `constitution.md`.

## Layout do repo (alvo)

```
databricks.yml                     # variables catalog=leadscore nos targets dev/prod
resources/
  leadscore.schemas.yml            # schemas bronze/silver/gold (landing + volumes também, se suportado)
  leadscore.pipeline.yml           # pipeline Lakeflow serverless, catalog ${var.catalog}
  leadscore.job.yml                # job: refresh do pipeline (agendável para a fila das 8h)
  leadscore.app.yml                # Databricks App (AppKit) + recursos (warehouse, Genie)
src/pipeline/
  bronze/{leads,empresas,oportunidades}.sql
  silver/{leads_normalizados,leads,empresas,historico_empresa}.sql
  gold/{leads_ia,leads_classificados,fila_do_dia}.sql
src/sql/
  udf_cnpj.sql                     # funções SQL de normalização/validação de CNPJ
  feedback_contatos.sql            # DDL da tabela escrita pelo app
  verificacao/*.sql                # consultas que provam cada CA
app/                               # AppKit (Node/React)
tests/                             # pytest + Databricks Connect (tests/conftest.py existente)
```

## Pipeline (SQL, Lakeflow declarativo)

| Objeto | Tipo | Notas |
|---|---|---|
| `bronze.leads_raw`, `bronze.empresas_raw`, `bronze.oportunidades_raw` | Streaming table | `STREAM read_files('/Volumes/leadscore/landing/raw/<pasta>/', format => 'csv', header => true, schemaHints => 'recebido_em TIMESTAMP')`; `_metadata.file_path AS _arquivo`, `current_timestamp() AS _ingerido_em`; coluna `_rescued_data` mantida |
| `silver.leads_normalizados` | Streaming table | Uma linha por linha da Bronze: e-mail `lower(trim())`, CNPJ só dígitos + `cnpj_valido`, `msg_curta = length(trim(mensagem)) < 5` |
| `gold.leads_ia` | Streaming table | `FROM STREAM silver.leads_normalizados`; `ai_classify` + `ai_extract` só quando `NOT msg_curta`; grava `ia_versao = '2.1'`. Incremental → CA-12 |
| `silver.empresas`, `silver.historico_empresa` | Materialized view | Empresas por CNPJ normalizado; histórico agregado (`oportunidades_ganhas`, `ja_cliente`, produtos ganhos) |
| `silver.leads` | Materialized view | Dedup por e-mail com `QUALIFY row_number() OVER (PARTITION BY email ORDER BY recebido_em DESC, _ingerido_em DESC) = 1` + join empresa/histórico + expectations |
| `gold.leads_classificados` | Materialized view | `silver.leads JOIN gold.leads_ia USING (lead_id)` + score, componentes, motivo, próximo passo |
| `gold.fila_do_dia` | Materialized view | Top 20 por score (sem spam/suporte), `posicao` 1..20, vendedor por rodízio `(posicao-1) % 4` |

**Decisão de ordem:** a IA roda por linha da Bronze (antes do dedup) porque a dedup "mais recente" exige visão do conjunto (MV), e uma MV não alimenta streaming incremental. Custo: 100 chamadas em vez de 96 no dia da demo; em troca, reexecução = 0 chamadas.

**Recência:** comparar `date(recebido_em)` com a data extraída do nome do arquivo (`leads_AAAA-MM-DD.csv`), não com `current_date()`, para a demo ser reprodutível.

**Vendedores:** 4 nomes fixos num `VALUES` dentro de `fila_do_dia.sql` (definir na T3.5).

## Tabela fora do pipeline
`gold.feedback_contatos (lead_id STRING, vendedor STRING, contatado_em TIMESTAMP, resultado STRING)` criada por DDL (T3.6) e escrita pelo app.

## Data App (AppKit)
- Scaffold e deploy seguindo a skill `databricks-apps`; UX seguindo `databricks-app-design`; referências visuais em `app_referencia/*.png`.
- Leitura via SQL warehouse; escrita do "contatado" com `INSERT` em `gold.feedback_contatos`.
- Agente: Genie Space (skill `databricks-genie-agents`) sobre as 3 tabelas Gold, instruções em português e as 5 perguntas do PRD §2.8 como exemplos; o app usa a Genie Conversation API. O `space_id` vira variável do bundle.
- Permissões do service principal do app: `USE CATALOG/SCHEMA`, `SELECT` nas tabelas Gold, `MODIFY` em `feedback_contatos`, `CAN_USE` no warehouse, acesso ao Genie Space.

## Verificação
- Cada CA tem uma consulta em `src/sql/verificacao/` e, quando fizer sentido, um teste em `tests/` (`uv run pytest`).
- Acurácia da IA: join de `gold.leads_ia` com o gabarito `data/lead_score_dados/gabarito/intencao.csv` (no Volume `gabarito`). Nunca usar `data/gabarito/` (geração antiga).
