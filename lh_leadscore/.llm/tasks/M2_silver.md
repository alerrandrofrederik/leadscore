# M2 · Silver

**Objetivo:** dados limpos, sem duplicidade e unidos (lead + empresa + histórico).
**Pronto quando:** CA-03 e CA-04 aprovados. → PRD §2.6 (RF-03..06), §3.1, `plan.md` (ordem IA × dedup)

---

## T2.1 · Funções de CNPJ
- Status: [x] concluída
- Requisitos: RF-03 · Aceite: CA-03
- Depende de: T0.2
- Arquivos: `src/sql/udf_cnpj.sql`
- Fazer: SQL functions em `leadscore.silver`: `cnpj_normalizar(s)` (só dígitos, 14 chars ou NULL) e `cnpj_valido(s)` (dígitos verificadores, rejeita sequências repetidas).
- Verificar: testes com CNPJ com máscara, sem máscara, com espaços (mesmo resultado) e os 2 inválidos do dataset (`false`).
- Evidência: 2026-11-26 · src/sql/udf_cnpj.sql (cnpj_normalizar, cnpj_dv, cnpj_valido). Testes: com e sem máscara → true; 11.111.111/1111-11 → false; '' → NULL; DV errado → false. No dataset: 2 inválidos (L20261123-0019, L20261123-0082).

## T2.2 · `silver.leads_normalizados`
- Status: [x] concluída
- Requisitos: RF-03 · Aceite: CA-03
- Depende de: T1.2, T2.1
- Arquivos: `src/pipeline/silver/leads_normalizados.sql`
- Fazer: streaming table `FROM STREAM bronze.leads_raw`: `email = lower(trim(email))` (remover espaços internos), `cnpj`, `cnpj_valido`, `msg_curta = coalesce(length(trim(mensagem)), 0) < 5`, `data_arquivo` extraída de `_arquivo`. Uma linha por linha da Bronze (alimenta a IA incremental na T3.1).
- Verificar: 100 linhas; nenhum e-mail com maiúscula ou espaço.
- Evidência: 2026-11-26 · leads_normalizados = 100 linhas; e-mail sem espaço e em minúsculas.

## T2.3 · `silver.empresas` e `silver.historico_empresa`
- Status: [x] concluída
- Requisitos: RF-05 · Aceite: —
- Depende de: T1.3, T2.1
- Arquivos: `src/pipeline/silver/empresas.sql`, `src/pipeline/silver/historico_empresa.sql`
- Fazer: empresas com CNPJ normalizado (1 por CNPJ); histórico agregado por CNPJ: `oportunidades_ganhas`, `ja_cliente = oportunidades_ganhas > 0`, produtos ganhos (para o bônus de cross-sell).
- Verificar: `count(DISTINCT cnpj) = count(*)` em ambas; soma de ganhas = 49.
- Evidência: 2026-11-26 · silver.empresas = 121 (1 por CNPJ); historico_empresa soma 49 ganhas.

## T2.4 · `silver.leads` (dedup + junção + expectations)
- Status: [x] concluída
- Requisitos: RF-04, RF-05, RF-06 · Aceite: CA-03, CA-04
- Depende de: T2.2, T2.3
- Arquivos: `src/pipeline/silver/leads.sql`
- Fazer: materialized view; dedup `QUALIFY row_number() OVER (PARTITION BY email ORDER BY recebido_em DESC, _ingerido_em DESC) = 1`; `LEFT JOIN` empresas e histórico por CNPJ; expectations (ex.: `email IS NOT NULL`, `lead_id IS NOT NULL`, `cnpj_valido` como WARN) registradas no event log.
- Verificar: ver T2.5.
- Evidência: 2026-11-26 · silver.leads (MV) com dedup, joins e 5 expectations (2 drop, 3 warn).

## T2.5 · Provar CA-03 e CA-04
- Status: [x] concluída
- Requisitos: RF-03, RF-04 · Aceite: CA-03, CA-04
- Depende de: T2.4
- Arquivos: `src/sql/verificacao/ca03_ca04_silver.sql`
- Verificar:
  - `SELECT count(*), count(DISTINCT email) FROM leadscore.silver.leads` = **96, 96**.
  - CNPJs com e sem máscara do mesmo lead/empresa convergem no mesmo valor.
  - `count_if(cnpj_valido = false)` = **2** (entre os não vazios).
  - O lead do reenvio que evolui sobrevive como `L20261123-0064` com a mensagem de compra.
  - Violações das expectations visíveis no event log do pipeline.
- Evidência: 2026-11-26 · ca03_ca04_silver.sql: 96 leads / 96 e-mails; 2 CNPJs inválidos; 0 CNPJs fora de 14 dígitos; 0 válidos sem empresa; L20261123-0064 sobrevive (compra) sobre L20261123-0025 (avaliando). Dups: 0056/0065, 0051/0052 (duplo clique), 0008/0021, 0025/0064.

---

## Checklist do marco
- [x] T2.1 · [x] T2.2 · [x] T2.3 · [x] T2.4 · [x] T2.5
- [x] CA-03 · [x] CA-04
