# Spec · o que entregar

Resumo navegável do `PRD_leadscore.md`. Detalhes sempre no PRD.

## Problema e meta
100 leads/dia, capacidade de 20 contatos. Escolher os 20 com maior chance de compra, usando os dados do lead, da empresa e do histórico, e a IA para ler a mensagem livre. → PRD §1.1–1.9

## Escopo
- **Dentro:** ingestão incremental de CSV, limpeza/dedup/junção, `ai_classify` + `ai_extract`, Lead Score explicável, Fila do Dia (20), Data App com agente Genie. → PRD §2.2
- **Fora:** CRM/APIs, `ai_query`, escrita no CRM, modelo de ML. → PRD §2.2

## Entradas
CSVs de `leads/`, `empresas/`, `historico/` no Volume `raw`; gabarito fora do `raw`. Dataset do dia 2026-11-23 em `data/lead_score_dados/`. → PRD §2.4

## Saídas
- `gold.leads_classificados` (todos os leads), `gold.fila_do_dia` (20, 5 por vendedor), `gold.feedback_contatos`. → PRD §2.10
- Data App: Fila do Dia, Visão do Gestor, agente. → PRD §2.6 (RF-13..16), §2.8

## Requisitos → marco → aceite

| Requisito | Assunto | Marco | Aceite |
|---|---|---|---|
| RF-01 | Auto Loader das 3 pastas | M1 | CA-01 |
| RF-02 | `_arquivo`, `_ingerido_em`, `_rescued_data` | M1 | CA-02 |
| RF-03 | Normalizar e-mail e CNPJ (DV) | M2 | CA-03 |
| RF-04 | Dedup por e-mail, mais recente | M2 | CA-03, CA-04 |
| RF-05 | Lead + empresa + histórico agregado | M2 | CA-03 |
| RF-06 | Expectations | M2 | CA-03 |
| RF-07 | `ai_classify` | M3 | CA-05, CA-06 |
| RF-08 | `ai_extract` | M3 | CA-07 |
| RF-09 | Lead Score com componentes | M3 | CA-08, CA-09 |
| RF-10 | Motivo e próximo passo por regra | M3 | CA-09 |
| RF-11 | `gold.fila_do_dia` | M3 | CA-09 |
| RF-12 | `gold.leads_classificados` | M3 | CA-11 |
| RF-13 | Tela Fila do Dia | M4 | CA-10 |
| RF-14 | Marcar como contatado | M4 | CA-10 |
| RF-15 | Visão do Gestor | M4 | CA-11 |
| RF-16 | Agente (Genie) | M4 | CA-11 |
| — | Custo: 0 chamadas na reexecução | M3 | CA-12 |
| — | SLA: upload → app ≤ 15 min | M4 | CA-13 |

## Regra do score
`0,50 × intenção + 0,25 × perfil + 0,15 × sinais + 0,10 × recência`, com travas de spam/suporte. → PRD §2.7

## Perguntas do agente (respostas esperadas)
5 perguntas, fechando com "6 leads de compra imediata fora da fila". → PRD §2.8
