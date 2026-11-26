# Constituição do projeto

Regras não negociáveis. Uma tarefa que precise quebrar alguma delas para e pede decisão.

## 1. Fonte da verdade
- `PRD_leadscore.md` manda. Se código e PRD divergirem, o PRD é corrigido primeiro (com aprovação) e depois o código.
- Números esperados (100 linhas, 96 únicos, 26 compra imediata, 6 fora da fila etc.) vêm do PRD §2.4 e de `data/README.md`. Não "ajuste" o dado para bater o teste.

## 2. Nomes
- Bundle `lh_leadscore` · catálogo `leadscore` · profile CLI `leadscore`.
- Schemas: `landing` (volumes), `bronze`, `silver`, `gold`.
- Volumes: `/Volumes/leadscore/landing/raw/{leads,empresas,historico}/` e `/Volumes/leadscore/landing/gabarito/`.
- Todo comando `databricks` leva `--profile leadscore`. Nunca use o profile padrão.
- `lh_ensaio05`, `scripts/preflight.sh` e o profile `lead_score` são de outro projeto: não use.

## 3. IA
- `ai_classify` e `ai_extract` com `map('version', '2.1')`, rótulos, descrições e schema **literais** do PRD §2.5.
- A IA roda só em linhas novas (streaming/incremental). Reprocessar sem arquivo novo = 0 chamadas (CA-12).
- Mensagem vazia ou com menos de 5 caracteres vira `spam` sem chamar a IA.
- A versão da função é gravada junto do resultado.
- Sem `ai_query` e sem modelo de ML no MVP (PRD §2.2, D-04, D-06).

## 4. Regras de negócio
- Score, motivo e próximo passo são **regra explícita em SQL** (PRD §2.7, RF-10). Pesos e pontos só mudam no PRD.
- `spam` → score 0 e "Descartar"; `suporte` → fora da fila e "Encaminhar ao suporte".
- Todo lead expõe os 4 componentes do score.

## 5. Plataforma
- Serverless em tudo (pipeline, jobs, app).
- Recursos declarados no bundle (`resources/*.yml`) e implantados com `databricks bundle deploy`. Criação manual só onde a tarefa disser (ex.: Genie Space, upload de CSV).
- Pipeline em SQL (Lakeflow declarativo). App em AppKit (Node/React).

## 6. Pronto
- Tarefa só fica `[x]` com o bloco **Verificar** executado e a evidência registrada.
- Marco só fecha com todos os CAs dele aprovados.
