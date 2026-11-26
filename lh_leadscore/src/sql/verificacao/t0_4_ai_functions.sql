-- T0.4 · Valida ai_classify e ai_extract (versão 2.1) na mensagem herói (L20261123-0089).
-- Esperado: intencao = compra_imediata; produto = Atlas Gestão, qtd = 200, prazo = dezembro,
-- orcamento = true, cargo = Diretor Financeiro, concorrente = OmniERP.
WITH m AS (
  SELECT 'Boa tarde, sou Diretor Financeiro da Metalúrgica Bandeirantes. Precisamos de 200 licenças do Atlas Gestão até dezembro, o orçamento já está aprovado. Hoje usamos o OmniERP e queremos migrar. Podemos agendar uma reunião?' AS mensagem
),
ia AS (
  SELECT
    ai_classify(
      mensagem,
      '{
        "compra_imediata": "Quer comprar produtos da Atlas Software: pede preço, proposta, quantidade de licenças, prazo ou reunião comercial",
        "avaliando":       "Quer conhecer os produtos da Atlas, comparar opções ou ver uma demonstração, sem urgência",
        "suporte":         "Já é cliente da Atlas e relata problema, dúvida de uso ou pede ajuda técnica",
        "spam":            "Sem relação com comprar da Atlas: oferta ou propaganda de terceiros (SEO, empréstimo, marketing), teste ou texto sem sentido, mesmo que use palavras como urgente, proposta ou preço"
      }',
      map('version', '2.1')
    ) AS intencao_raw,
    ai_extract(
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
    ) AS entidades_raw
  FROM m
)
SELECT
  intencao_raw:response[0].value::string             AS intencao,
  entidades_raw:response.produto.value::string       AS produto,
  entidades_raw:response.qtd_licencas.value::int     AS qtd_licencas,
  entidades_raw:response.prazo.value::string         AS prazo,
  entidades_raw:response.orcamento_aprovado.value::boolean AS orcamento_aprovado,
  entidades_raw:response.cargo.value::string         AS cargo,
  entidades_raw:response.concorrente_citado.value::string  AS concorrente_citado,
  to_json(intencao_raw)  AS intencao_json,
  to_json(entidades_raw) AS entidades_json
FROM ia
