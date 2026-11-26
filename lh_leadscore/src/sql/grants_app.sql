-- M4 · T4.1 · Permissões mínimas do service principal do Data App (idempotente).
-- O principal é o service_principal_client_id do app:
--   databricks apps get leadscore-leadscorews --profile leadscore -o json | grep service_principal_client_id
-- Rodar com:
--   databricks experimental aitools tools query --file src/sql/grants_app.sql \
--     --param app_sp=<service_principal_client_id> --profile leadscore
BEGIN
  DECLARE sp STRING DEFAULT :app_sp;
  EXECUTE IMMEDIATE 'GRANT USE CATALOG ON CATALOG leadscore TO `' || sp || '`';
  EXECUTE IMMEDIATE 'GRANT USE SCHEMA ON SCHEMA leadscore.gold TO `' || sp || '`';
  EXECUTE IMMEDIATE 'GRANT USE SCHEMA ON SCHEMA leadscore.silver TO `' || sp || '`';
  EXECUTE IMMEDIATE 'GRANT USE SCHEMA ON SCHEMA leadscore.landing TO `' || sp || '`';
  -- leitura das tabelas do app
  EXECUTE IMMEDIATE 'GRANT SELECT ON TABLE leadscore.gold.leads_classificados TO `' || sp || '`';
  EXECUTE IMMEDIATE 'GRANT SELECT ON TABLE leadscore.gold.fila_do_dia TO `' || sp || '`';
  EXECUTE IMMEDIATE 'GRANT SELECT ON TABLE leadscore.gold.leads_ia TO `' || sp || '`';
  EXECUTE IMMEDIATE 'GRANT SELECT ON TABLE leadscore.silver.leads_normalizados TO `' || sp || '`';
  -- escrita do botão "Marcar como contatado" (RF-14)
  EXECUTE IMMEDIATE 'GRANT SELECT, MODIFY ON TABLE leadscore.gold.feedback_contatos TO `' || sp || '`';
  -- acurácia da IA na Visão do Gestor (lê o gabarito)
  EXECUTE IMMEDIATE 'GRANT READ VOLUME ON VOLUME leadscore.landing.gabarito TO `' || sp || '`';
END;
