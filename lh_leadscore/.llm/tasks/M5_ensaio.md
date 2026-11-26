# M5 · Ensaio

**Objetivo:** demo de 50 min reproduzível, com plano B.
**Pronto quando:** Portão 3 fechado (CA-01 a CA-13 aprovados + ensaio dentro de 50 min). → PRD §3.2, §5

---

## T5.1 · Alinhar a apresentação aos nomes do projeto
- Status: [x] concluída
- Requisitos: — · Aceite: —
- Depende de: M3 concluído (nomes finais de tabelas/pipeline)
- Arquivos: `apresentacao/lead_score.html`
- Fazer: trocar `lh_ensaio05` → `leadscore`, `lh_ensaio05_pipeline` → `lh_leadscore_pipeline`, `--profile lead_score` → `--profile leadscore`; remover `bash scripts/preflight.sh` (usar os passos do M0); conferir nomes de tabelas citados (ex.: `gold.leads_ia`) com o que foi implementado.
- Verificar: `grep -n "ensaio05\|preflight\|lead_score\b" apresentacao/lead_score.html` sem ocorrências indevidas.
- Evidência: 2026-11-26 · lead_score.html refatorado: catálogo leadscore, profile leadscore, repo leadscore, bundle lh_leadscore (target dev, sem -t prod), setup por src/sql/*.sql no lugar do preflight, warehouse 4c2bc55088722e76, app leadscore-leadscorews, objetos Silver/Gold reais, top 5 real (herói em 2º), CA-09..CA-12 atualizados, anexos A e B com os comandos e erros deste projeto. grep sem ocorrências de ensaio05/lh_ensaio/preflight/-t prod; página renderiza (a exceção no console já existia antes).

## T5.2 · Roteiro de reset da demo
- Status: [ ] pendente
- Requisitos: CA-01, CA-13 (pré-condição) · Aceite: —
- Depende de: M4 concluído
- Arquivos: `src/sql/reset_demo.sql`, seção no `README.md` do projeto
- Fazer: passos para voltar ao estado "antes do ao vivo": remover o CSV de leads de `raw/leads/`, full refresh do pipeline, `DELETE FROM leadscore.gold.feedback_contatos`, manter empresas/histórico/gabarito.
- Verificar: após o reset, `bronze.leads_raw` vazia e app mostrando fila vazia; após subir o CSV, CA-01 se repete.
- Evidência:

## T5.3 · Plano B
- Status: [ ] pendente
- Requisitos: riscos PRD §3.2 · Aceite: —
- Depende de: M4 concluído
- Arquivos: anotar no `README.md` do projeto
- Fazer: pipeline pré-executado e app já publicado; resultado da IA pré-processado como fallback; gravar vídeo de backup do fluxo completo.
- Verificar: o vídeo existe e cobre Demo 1 e Demo 2.
- Evidência:

## T5.4 · Ensaio cronometrado e Portão 3
- Status: [ ] pendente
- Requisitos: todos · Aceite: CA-01 a CA-13
- Depende de: T5.1, T5.2, T5.3
- Fazer: executar o roteiro do PRD §5 do zero (reset → upload ao vivo → consultas → app → 5 perguntas), cronometrando cada bloco.
- Verificar: total ≤ 50 min; todos os checklists de M1–M4 marcados; marcar o Portão 3 no PRD.
- Evidência:

---

## Checklist do marco
- [x] T5.1 · [ ] T5.2 · [ ] T5.3 · [ ] T5.4
- [ ] Portão 3
