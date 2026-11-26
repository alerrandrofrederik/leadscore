-- RF-09, RF-10, RF-12 · Todos os leads únicos com intenção, entidades, Lead Score explicável, motivo e próximo passo.
-- lead_score = 0,50 × intenção + 0,25 × perfil + 0,15 × sinais + 0,10 × recência (PRD §2.7).
CREATE OR REFRESH MATERIALIZED VIEW gold.leads_classificados (
  lead_id            STRING  COMMENT 'Identificador do lead',
  nome               STRING  COMMENT 'Nome de quem enviou',
  email              STRING  COMMENT 'E-mail normalizado (chave de deduplicação)',
  telefone           STRING  COMMENT 'Telefone informado',
  empresa            STRING  COMMENT 'Razão social da empresa (pelo CNPJ)',
  cnpj               STRING  COMMENT 'CNPJ com 14 dígitos',
  canal              STRING  COMMENT 'Canal de origem: site, linkedin, evento, indicacao, google_ads',
  campanha           STRING  COMMENT 'Campanha de marketing',
  porte              STRING  COMMENT 'Porte da empresa: grande, médio, pequeno ou desconhecido',
  segmento           STRING  COMMENT 'Segmento da empresa',
  uf                 STRING  COMMENT 'UF da empresa',
  ja_cliente         BOOLEAN COMMENT 'Empresa tem oportunidade ganha no histórico',
  mensagem           STRING  COMMENT 'Mensagem original do lead',
  intencao           STRING  COMMENT 'Intenção pelo ai_classify: compra_imediata, avaliando, suporte ou spam',
  produto            STRING  COMMENT 'Produto Atlas citado (ai_extract)',
  qtd_licencas       INT     COMMENT 'Quantidade de licenças ou usuários pedida (ai_extract)',
  prazo              STRING  COMMENT 'Prazo desejado (ai_extract)',
  orcamento_aprovado BOOLEAN COMMENT 'Mencionou orçamento aprovado (ai_extract)',
  cargo              STRING  COMMENT 'Cargo de quem escreveu (ai_extract)',
  concorrente_citado STRING  COMMENT 'Sistema concorrente citado (ai_extract); nulo se não citou',
  lead_score         INT     COMMENT 'Lead Score de 0 a 100',
  score_componentes  STRUCT<intencao: INT, perfil: INT, sinais: INT, recencia: INT> COMMENT 'Os 4 componentes do score, cada um de 0 a 100',
  motivo             STRING  COMMENT 'Por que o lead tem esse score (gerado por regra)',
  proximo_passo      STRING  COMMENT 'Ação recomendada (gerada por regra)',
  data_arquivo       DATE    COMMENT 'Dia do arquivo de leads (dia da fila)',
  recebido_em        TIMESTAMP COMMENT 'Quando o lead chegou',
  processado_em      TIMESTAMP COMMENT 'Quando a IA processou o lead',
  ia_versao          STRING  COMMENT 'Versão das AI Functions usada'
)
COMMENT 'Todos os leads únicos classificados pela IA, com Lead Score, motivo e próximo passo'
AS
WITH base AS (
  SELECT l.*, ia.intencao, ia.produto, ia.qtd_licencas, ia.prazo, ia.orcamento_aprovado,
         ia.cargo, ia.concorrente_citado, ia.processado_em, ia.ia_versao
  FROM silver.leads l
  JOIN gold.leads_ia ia USING (lead_id)
),
comp AS (
  SELECT *,
    CASE intencao WHEN 'compra_imediata' THEN 100 WHEN 'avaliando' THEN 40 ELSE 0 END AS c_intencao,
    least(100,
      CASE porte WHEN 'grande' THEN 100 WHEN 'médio' THEN 60 WHEN 'medio' THEN 60 WHEN 'pequeno' THEN 30 ELSE 20 END
      + CASE WHEN ja_cliente AND produto IS NOT NULL AND NOT array_contains(produtos_ganhos, produto) THEN 20 ELSE 0 END
    ) AS c_perfil,
    least(100,
      CASE WHEN orcamento_aprovado THEN 40 ELSE 0 END
      + CASE WHEN prazo IS NOT NULL AND trim(prazo) <> '' THEN 30 ELSE 0 END
      + CASE WHEN qtd_licencas IS NOT NULL THEN 30 ELSE 0 END
    ) AS c_sinais,
    CASE datediff(data_arquivo, to_date(recebido_em))
      WHEN 0 THEN 100 WHEN 1 THEN 50 WHEN 2 THEN 25 ELSE 0
    END AS c_recencia
  FROM base
)
SELECT
  lead_id, nome, email, telefone, empresa, cnpj, canal, campanha, porte, segmento, uf, ja_cliente, mensagem,
  intencao, produto, qtd_licencas, prazo, orcamento_aprovado, cargo, concorrente_citado,
  CASE WHEN intencao = 'spam' THEN 0
       ELSE cast(round(0.50 * c_intencao + 0.25 * c_perfil + 0.15 * c_sinais + 0.10 * c_recencia) AS INT)
  END AS lead_score,
  named_struct('intencao', c_intencao, 'perfil', c_perfil, 'sinais', c_sinais, 'recencia', c_recencia) AS score_componentes,
  CASE intencao
    WHEN 'spam'    THEN 'Mensagem sem relação com compra'
    WHEN 'suporte' THEN 'Pedido de suporte de cliente'
    ELSE concat_ws(' · ', filter(array(
      CASE
        WHEN qtd_licencas IS NOT NULL AND produto IS NOT NULL THEN concat('Pediu ', qtd_licencas, ' licenças do ', produto, coalesce(concat(' até ', prazo), ''))
        WHEN produto IS NOT NULL THEN concat('Interesse no ', produto, coalesce(concat(' até ', prazo), ''))
        WHEN prazo IS NOT NULL THEN concat('Prazo: ', prazo)
      END,
      CASE WHEN porte <> 'desconhecido' THEN concat('empresa ', porte) END,
      CASE WHEN orcamento_aprovado THEN 'orçamento aprovado' END,
      CASE WHEN ja_cliente THEN 'já é cliente' END,
      CASE WHEN concorrente_citado IS NOT NULL THEN concat('usa ', concorrente_citado) END
    ), x -> x IS NOT NULL))
  END AS motivo,
  CASE intencao
    WHEN 'compra_imediata' THEN 'Ligar hoje e enviar proposta'
    WHEN 'avaliando'       THEN 'Agendar demonstração'
    WHEN 'suporte'         THEN 'Encaminhar ao suporte'
    ELSE 'Descartar'
  END AS proximo_passo,
  data_arquivo, recebido_em, processado_em, ia_versao
FROM comp;
