# M2 · Silver

**Objetivo:** dados limpos, sem duplicidade e unidos (lead + empresa + histórico).
**Pronto quando:** CA-03 e CA-04 aprovados. → PRD §2.6 (RF-03..06), §3.1, `plan.md` (ordem IA × dedup)

---

## T2.1 · Funções de CNPJ
- Status: [ ] pendente
- Requisitos: RF-03 · Aceite: CA-03
- Depende de: T0.2
- Arquivos: `src/sql/udf_cnpj.sql`
- Fazer: SQL functions em `leadscore.silver`: `cnpj_normalizar(s)` (só dígitos, 14 chars ou NULL) e `cnpj_valido(s)` (dígitos verificadores, rejeita sequências repetidas).
- Verificar: testes com CNPJ com máscara, sem máscara, com espaços (mesmo resultado) e os 2 inválidos do dataset (`false`).
- Evidência:

## T2.2 · `silver.leads_normalizados`
- Status: [ ] pendente
- Requisitos: RF-03 · Aceite: CA-03
- Depende de: T1.2, T2.1
- Arquivos: `src/pipeline/silver/leads_normalizados.sql`
- Fazer: streaming table `FROM STREAM bronze.leads_raw`: `email = lower(trim(email))` (remover espaços internos), `cnpj`, `cnpj_valido`, `msg_curta = coalesce(length(trim(mensagem)), 0) < 5`, `data_arquivo` extraída de `_arquivo`. Uma linha por linha da Bronze (alimenta a IA incremental na T3.1).
- Verificar: 100 linhas; nenhum e-mail com maiúscula ou espaço.
- Evidência:

## T2.3 · `silver.empresas` e `silver.historico_empresa`
- Status: [ ] pendente
- Requisitos: RF-05 · Aceite: —
- Depende de: T1.3, T2.1
- Arquivos: `src/pipeline/silver/empresas.sql`, `src/pipeline/silver/historico_empresa.sql`
- Fazer: empresas com CNPJ normalizado (1 por CNPJ); histórico agregado por CNPJ: `oportunidades_ganhas`, `ja_cliente = oportunidades_ganhas > 0`, produtos ganhos (para o bônus de cross-sell).
- Verificar: `count(DISTINCT cnpj) = count(*)` em ambas; soma de ganhas = 49.
- Evidência:

## T2.4 · `silver.leads` (dedup + junção + expectations)
- Status: [ ] pendente
- Requisitos: RF-04, RF-05, RF-06 · Aceite: CA-03, CA-04
- Depende de: T2.2, T2.3
- Arquivos: `src/pipeline/silver/leads.sql`
- Fazer: materialized view; dedup `QUALIFY row_number() OVER (PARTITION BY email ORDER BY recebido_em DESC, _ingerido_em DESC) = 1`; `LEFT JOIN` empresas e histórico por CNPJ; expectations (ex.: `email IS NOT NULL`, `lead_id IS NOT NULL`, `cnpj_valido` como WARN) registradas no event log.
- Verificar: ver T2.5.
- Evidência:

## T2.5 · Provar CA-03 e CA-04
- Status: [ ] pendente
- Requisitos: RF-03, RF-04 · Aceite: CA-03, CA-04
- Depende de: T2.4
- Arquivos: `src/sql/verificacao/ca03_ca04_silver.sql`
- Verificar:
  - `SELECT count(*), count(DISTINCT email) FROM leadscore.silver.leads` = **96, 96**.
  - CNPJs com e sem máscara do mesmo lead/empresa convergem no mesmo valor.
  - `count_if(cnpj_valido = false)` = **2** (entre os não vazios).
  - O lead do reenvio que evolui sobrevive como `L20261123-0064` com a mensagem de compra.
  - Violações das expectations visíveis no event log do pipeline.
- Evidência:

---

## Checklist do marco
- [ ] T2.1 · [ ] T2.2 · [ ] T2.3 · [ ] T2.4 · [ ] T2.5
- [ ] CA-03 · [ ] CA-04
