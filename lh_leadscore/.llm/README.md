# .llm · Spec Driven Development do Lead Score

Esta pasta guia a implementação do `PRD_leadscore.md` por agentes (ou pessoas) em passos rastreáveis.

## Fluxo

```
constitution.md  →  spec.md  →  plan.md  →  tasks/Mx_*.md  →  código  →  verificação (CA)
 regras fixas       o quê       o como       passos            commit     prova
```

1. **constitution.md**: regras que nenhuma tarefa pode quebrar. Leia sempre.
2. **spec.md**: o que entregar, com ponteiros para as seções do PRD (o PRD é a fonte da verdade).
3. **plan.md**: decisões técnicas e onde cada coisa mora no repo.
4. **tasks/**: uma lista de tarefas por marco do PRD (§4). Cada tarefa cita RF/CA, dependências, arquivos e como verificar.

## Como executar uma tarefa

1. Escolha a primeira tarefa `[ ] pendente` cujas dependências estejam `[x]`.
2. Marque `[~] em andamento`.
3. Implemente só o que a tarefa pede, nos arquivos listados.
4. Rode o bloco **Verificar** e cole o resultado (resumo) na linha `Evidência`.
5. Marque `[x] concluída`. Se a verificação falhar, mantenha `[~]` e anote o bloqueio.
6. Se a implementação exigir mudar a spec, atualize o PRD primeiro e depois `spec.md`/`plan.md`.

Status: `[ ]` pendente · `[~]` em andamento · `[x]` concluída · `[!]` bloqueada

## Índice

| Marco | Arquivo | Pronto quando |
|---|---|---|
| M0 · Ambiente | [tasks/M0_ambiente.md](tasks/M0_ambiente.md) | Catálogo, schemas, volumes e CSVs de apoio verificados |
| M1 · Bronze | [tasks/M1_bronze.md](tasks/M1_bronze.md) | CA-01, CA-02 |
| M2 · Silver | [tasks/M2_silver.md](tasks/M2_silver.md) | CA-03, CA-04 |
| M3 · Gold | [tasks/M3_gold.md](tasks/M3_gold.md) | CA-05 a CA-09, CA-12 |
| M4 · Data App | [tasks/M4_data_app.md](tasks/M4_data_app.md) | CA-10, CA-11, CA-13 |
| M5 · Ensaio | [tasks/M5_ensaio.md](tasks/M5_ensaio.md) | Portão 3 |
