-- RF-07, RF-08 · Intenção (ai_classify) e entidades (ai_extract) da mensagem do lead.
-- Streaming: a IA roda só nas linhas novas (CA-12). Mensagem com menos de 5 caracteres vira spam sem chamar a IA.
-- Rótulos, descrições e schema são regra de negócio: copiados literalmente do PRD §2.5.
CREATE OR REFRESH STREAMING TABLE gold.leads_ia
COMMENT 'Saída das AI Functions por envio de lead (versão 2.1), com o retorno bruto para auditoria'
AS
WITH ia AS (
  SELECT
    lead_id,
    msg_curta,
    CASE WHEN NOT msg_curta THEN ai_classify(
      mensagem,
      '{
        "compra_imediata": "Quer comprar produtos da Atlas Software: pede preço, proposta, quantidade de licenças, prazo ou reunião comercial",
        "avaliando":       "Quer conhecer os produtos da Atlas, comparar opções ou ver uma demonstração, sem urgência",
        "suporte":         "Já é cliente da Atlas e relata problema, dúvida de uso ou pede ajuda técnica",
        "spam":            "Sem relação com comprar da Atlas: oferta ou propaganda de terceiros (SEO, empréstimo, marketing), teste ou texto sem sentido, mesmo que use palavras como urgente, proposta ou preço"
      }',
      map('version', '2.1')
    ) END AS intencao_raw,
    CASE WHEN NOT msg_curta THEN ai_extract(
      mensagem,
      '{
        "produto":            {"type": "string",  "description": "Produto Atlas citado"},
        "qtd_licencas":       {"type": "integer", "description": "Quantidade de licenças ou usuários"},
        "prazo":              {"type": "string",  "description": "Prazo ou data desejada, só o mês ou a data, sem preposição (ex.: dezembro)"},
        "orcamento_aprovado": {"type": "boolean", "description": "Mencionou orçamento aprovado"},
        "cargo":              {"type": "string",  "description": "Cargo de quem escreveu"},
        "concorrente_citado": {"type": "string",  "description": "Sistema concorrente de outra empresa que o lead usa ou avalia (nunca um produto Atlas)"}
      }',
      map('version', '2.1')
    ) END AS entidades_raw
  FROM STREAM(silver.leads_normalizados)
)
SELECT
  lead_id,
  CASE WHEN msg_curta THEN 'spam' ELSE intencao_raw:response[0].value::string END AS intencao,
  entidades_raw:response.produto.value::string             AS produto,
  entidades_raw:response.qtd_licencas.value::int           AS qtd_licencas,
  entidades_raw:response.prazo.value::string               AS prazo,
  entidades_raw:response.orcamento_aprovado.value::boolean AS orcamento_aprovado,
  entidades_raw:response.cargo.value::string               AS cargo,
  entidades_raw:response.concorrente_citado.value::string  AS concorrente_citado,
  CASE WHEN msg_curta THEN 'regra_msg_curta' ELSE 'ai_functions_2.1' END AS ia_origem,
  coalesce(intencao_raw:metadata.version::string, CASE WHEN NOT msg_curta THEN '2.1' END) AS ia_versao,
  coalesce(intencao_raw:error_message::string, entidades_raw:error_message::string)      AS ia_erro,
  intencao_raw,
  entidades_raw,
  current_timestamp() AS processado_em
FROM ia;
