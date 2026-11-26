# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que é este projeto

Workshop "Lead Score": um pipeline no Databricks que prioriza 100 leads/dia para 20 vagas de contato, usando `ai_classify`/`ai_extract`, e entrega uma Fila do Dia + agente Genie num Databricks App. A especificação completa (requisitos RF-xx, critérios de aceite CA-xx, regra do score, modelo Gold) está em `PRD_leadscore.md`: **é a fonte da verdade**; leia antes de implementar qualquer camada.

A implementação segue Spec Driven Development em `.llm/`: obedeça `.llm/constitution.md`, decisões técnicas em `.llm/plan.md`, tarefas por marco em `.llm/tasks/M0..M5_*.md`. Ao concluir uma tarefa, rode o bloco **Verificar**, registre a evidência e atualize o status.

Estado atual: apenas o scaffold do template `default-python` do DABs (`src/lh_leadscore/` vazio, `resources/` vazio). Pipeline, app e Genie Space ainda serão construídos (marcos M0–M5 do PRD).

## Nomes do ambiente

- Bundle: `lh_leadscore` (`databricks.yml`) · Catálogo UC: `leadscore` · Profile CLI: `leadscore`
- Volumes: `/Volumes/leadscore/landing/raw/{leads,empresas,historico}/` e `/Volumes/leadscore/landing/gabarito/`
- Schemas: `landing`, `bronze`, `silver`, `gold`
- Há vários profiles no `.databrickscfg` (DEFAULT, pessoal, leadscore): sempre passe `--profile leadscore` explicitamente.
- Atenção: `databricks.yml` ainda define `catalog: workspace` nos targets dev/prod; diverge do PRD (`leadscore`).
- Nomes `lh_ensaio05`, `scripts/preflight.sh` e profile `lead_score` são de um projeto anterior. Ainda aparecem em `apresentacao/lead_score.html` e não devem ser usados.

## Comandos

```bash
uv sync --dev                                  # instala dependências (Python 3.12, databricks-connect 16.4)
DATABRICKS_CONFIG_PROFILE=leadscore uv run pytest                     # testes de aceite (CA-01..09) via Databricks Connect
DATABRICKS_CONFIG_PROFILE=leadscore uv run pytest tests/test_aceite.py::test_ca07_entidades_do_heroi  # um teste
databricks experimental aitools tools query --file src/sql/<arquivo>.sql --profile leadscore  # SQL avulso (1 statement ou bloco BEGIN/END)
uv run ruff check . && uv run ruff format .    # lint/format (line-length 120)

databricks bundle validate --profile leadscore
databricks bundle deploy --target dev --profile leadscore   # dev é o target padrão
databricks bundle run <recurso> --profile leadscore

python data/gerar_csvs.py --data 2026-11-23    # regera o dataset (seed fixa 42, saída em data/lead_score_dados/)
```

Testes não rodam Spark local: `tests/conftest.py` cria uma `DatabricksSession` remota no `pytest_configure` (cai para serverless se nenhum cluster estiver configurado), então exigem autenticação válida no workspace. A fixture `load_fixture` lê JSON/CSV de `fixtures/`.

## Arquitetura planejada (PRD §2)

CSVs → Volume `raw` → Bronze (Auto Loader, Lakeflow declarativo, `_arquivo`/`_ingerido_em`, hint `recebido_em TIMESTAMP` com `_rescued_data`) → Silver (normaliza e-mail/CNPJ com dígito verificador, dedup por e-mail mantendo o mais recente, join com empresas e histórico agregado) → Gold (`ai_classify` + `ai_extract` versão 2.1, só em leads novos; `lead_score` = 0,50 intenção + 0,25 perfil + 0,15 sinais + 0,10 recência; motivo/próximo passo por regra, sem `ai_query`) → tabelas `gold.leads_classificados`, `gold.fila_do_dia` (20 leads, 5 por vendedor), `gold.feedback_contatos` → Databricks App + Genie Space.

Os prompts exatos dos rótulos do `ai_classify` e do schema do `ai_extract` estão no PRD §2.5. A descrição do rótulo `spam` é regra de negócio (corrige a pegadinha P2); não a simplifique.

## Dados

- `data/lead_score_dados/raw/`: CSVs do dia 2026-11-23 (leads 100 linhas → 96 únicos; 26 compra_imediata, 6 ficam fora da fila). Números esperados que os testes/aceites conferem estão em `data/README.md` e no PRD §2.4/§3.1.
- `data/lead_score_dados/gabarito/`: gabarito válido para medir acurácia da IA.
- `data/gabarito/` (raiz) é de uma geração antiga (IDs `L20261122-*`) e **não** deve ser usado.
- `app_referencia/*.png`: referências visuais de layout para o Data App.
- `apresentacao/lead_score.html`: roteiro/slides da demo.
