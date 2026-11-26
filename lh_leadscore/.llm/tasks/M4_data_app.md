# M4 · Data App

**Objetivo:** o time comercial usa a fila e conversa com o agente, dentro do workspace.
**Pronto quando:** CA-10, CA-11 e CA-13 aprovados. → PRD §2.6 (RF-13..16), §2.8, §3.1
**Skills:** `databricks-apps` (AppKit, scaffold/deploy), `databricks-app-design` (UX), `databricks-genie-agents` (Genie Space). Referências visuais: `app_referencia/*.png`.

---

## T4.1 · Scaffold AppKit e recurso do app
- Status: [x] concluída
- Requisitos: RF-13..16 · Aceite: —
- Depende de: T0.5, T3.4
- Arquivos: `app/`, `resources/leadscore.app.yml`
- Fazer: criar o app AppKit (Node/React) em `app/`; declarar no bundle com recursos SQL warehouse (`${var.warehouse_id}`) e, após a T4.5, o Genie Space. Grants do service principal: `USE CATALOG leadscore`, `USE SCHEMA gold`, `SELECT` em `leads_classificados` e `fila_do_dia`, `SELECT, MODIFY` em `feedback_contatos`.
- Verificar: `databricks bundle deploy --profile leadscore` e o app abre com o login do workspace.
- Evidência: 2026-11-26 · AppKit 0.84 (analytics + genie, npm) em app/; recurso resources/leadscore.app.yml no bundle raiz (app leadscore-leadscorews, user_api_scopes dashboards.genie). Grants do service principal em src/sql/grants_app.sql (USE CATALOG/SCHEMA, SELECT nas tabelas do app, MODIFY em feedback_contatos, READ VOLUME no gabarito). databricks apps validate passou; app RUNNING em https://leadscore-leadscorews-7474647553344962.aws.databricksapps.com.

## T4.2 · Tela Fila do Dia
- Status: [x] concluída
- Requisitos: RF-13 · Aceite: CA-10
- Depende de: T4.1
- Arquivos: `app/` (página/rota da fila, query em `gold.fila_do_dia`)
- Fazer: seletor de vendedor; 5 cards com score, intenção, motivo, entidades extraídas, próximo passo e os 4 componentes do score. Estados de carregando/vazio/erro.
- Verificar: para cada vendedor aparecem exatamente 5 cards; o lead herói está no topo do seu vendedor.
- Evidência: 2026-11-26 · Testado no navegador: filtro por vendedor; Bruno com 5 cards (#2, 6, 10, 14, 18); herói no topo com score 100, 4 barras de componentes, motivo, entidades, mensagem e próximo passo. Estados de carregando, vazio e erro implementados. Bug corrigido: o analytics devolve BOOLEAN como texto e 'false' contava como verdadeiro (helper bool()).

## T4.3 · Marcar como contatado
- Status: [x] concluída
- Requisitos: RF-14 · Aceite: CA-10
- Depende de: T4.2, T3.6
- Arquivos: `app/` (ação + endpoint de escrita)
- Fazer: botão "Marcar como contatado" → `INSERT INTO leadscore.gold.feedback_contatos` (lead_id, vendedor, `current_timestamp()`, resultado inicial). Parametrizar a query; card muda de estado.
- Verificar: após clicar, `SELECT * FROM leadscore.gold.feedback_contatos WHERE lead_id = '<id>'` retorna o registro.
- Evidência: 2026-11-26 · POST /api/contatos (zod + INSERT parametrizado, só para leads da fila; testes em server/contato.test.ts). Clique no herói → card 'Contatado' e '1 de 20 contatados'; feedback_contatos: L20261123-0089, Bruno, 2026-11-26T21:05:40Z, contatado.

## T4.4 · Visão do Gestor
- Status: [x] concluída
- Requisitos: RF-15 · Aceite: CA-11
- Depende de: T4.1
- Arquivos: `app/` (página do gestor)
- Fazer: funil do dia (recebidos → classificados → na fila → contatados) e distribuição por intenção e por canal, a partir das tabelas Gold.
- Verificar: números do funil batem com consultas diretas (100 → 96 → 20 → n contatados).
- Evidência: 2026-11-26 · Banner e 6 KPIs (100 recebidos, 96 classificados, 20 na fila, 1 contatado, 26 compra imediata com 6 fora, acurácia 100%), funil 100→96→20→1 e intenção por canal (barras empilhadas). Cache das queries renovado a cada minuto e a cada contato (parâmetro atualizacao).

## T4.5 · Genie Space
- Status: [x] concluída
- Requisitos: RF-16 · Aceite: CA-11
- Depende de: T3.4, T3.5, T3.6
- Arquivos: `src/genie/` (instruções e perguntas-exemplo versionadas), variável `genie_space_id` em `databricks.yml`
- Fazer: criar o space sobre `gold.leads_classificados`, `gold.fila_do_dia`, `gold.feedback_contatos`, com instruções em português e as 5 perguntas do PRD §2.8 (com SQL de exemplo). Conceder acesso ao service principal do app.
- Verificar: as 5 perguntas no próprio Genie retornam as respostas esperadas (26 · Indicação e LinkedIn · lista com o herói/OmniERP · contatos marcados · 6 leads).
- Evidência: 2026-11-26 · Genie Space 01f1e9d8c6461adc876c8997ad891040 criado com src/genie/gerar_space.py (3 tabelas Gold, instruções em PT-BR, 5 perguntas com SQL de exemplo). src/genie/testar_perguntas.py: as 5 respostas certas pela API. O título ficou com timestamp porque já existe um arquivo com o mesmo nome no workspace.

## T4.6 · Painel do agente no app
- Status: [x] concluída
- Requisitos: RF-16 · Aceite: CA-11
- Depende de: T4.1, T4.5
- Arquivos: `app/` (painel de chat + backend da Genie Conversation API)
- Fazer: painel de chat que inicia conversa e envia perguntas ao Genie Space, mostrando a resposta, a tabela de resultado e o SQL gerado (confiança no resultado da IA).
- Verificar: as 5 perguntas do roteiro, feitas pelo app, dão as respostas esperadas.
- Evidência: 2026-11-26 · Página Agente: useGenieChat + GenieChatMessageList, botões com as perguntas do roteiro, badge com o usuário (/api/whoami), card 'SQL gerado', status e erro, aviso de IA e de execução on-behalf-of.

## T4.7 · Provar CA-10, CA-11 e CA-13
- Status: [~] em andamento
- Requisitos: RF-13..16 · Aceite: CA-10, CA-11, CA-13
- Depende de: T4.2..T4.6
- Verificar:
  - **CA-10:** um vendedor vê seus 5 leads, marca um, o registro aparece em `feedback_contatos`.
  - **CA-11:** as 5 perguntas do PRD §2.8 respondidas corretamente no app.
  - **CA-13:** com o pipeline parado, apagar o estado da demo (ver T5.2), subir `leads_2026-11-23.csv`, disparar o job e cronometrar até o herói aparecer no app: ≤ **15 min**.
- Evidência: 2026-11-26 · CA-10 OK (contato registrado e visível na fila e no gestor). CA-11 OK no app: 26 · Indicação 10 / LinkedIn 9 · 4 concorrentes (herói/OmniERP) · 0 contatados antes do clique · 6 fora da fila. CA-13 PENDENTE: exige reset da demo (remover o CSV, refresh completo, limpar o feedback) e upload ao vivo, aguardando confirmação do usuário.

---

## Checklist do marco
- [x] T4.1 · [x] T4.2 · [x] T4.3 · [x] T4.4 · [x] T4.5 · [x] T4.6 · [ ] T4.7
- [x] CA-10 · [x] CA-11 · [ ] CA-13
