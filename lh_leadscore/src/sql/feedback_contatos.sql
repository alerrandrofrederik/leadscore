-- M3 · T3.6 · Tabela de feedback escrita pelo Data App (fora do pipeline). Idempotente.
-- Rodar com: databricks experimental aitools tools query --file src/sql/feedback_contatos.sql --profile leadscore
CREATE TABLE IF NOT EXISTS leadscore.gold.feedback_contatos (
  lead_id      STRING    COMMENT 'Lead contatado',
  vendedor     STRING    COMMENT 'Vendedor que fez o contato',
  contatado_em TIMESTAMP COMMENT 'Quando o vendedor marcou o contato',
  resultado    STRING    COMMENT 'Resultado do contato (ex.: contatado, sem_resposta, oportunidade)'
)
COMMENT 'Feedback dos vendedores: leads marcados como contatados no app';
