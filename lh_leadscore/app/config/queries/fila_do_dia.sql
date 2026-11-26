-- Fila do Dia (RF-13): os 20 leads priorizados com score, componentes, entidades e status de contato.
-- @param atualizacao STRING = inicial
WITH contatos AS (
  SELECT lead_id, max(contatado_em) AS contatado_em
  FROM leadscore.gold.feedback_contatos
  WHERE length(:atualizacao) >= 0
  GROUP BY lead_id
)
SELECT
  cast(f.data AS STRING)           AS data,
  f.posicao,
  f.vendedor,
  f.lead_id,
  f.nome,
  f.empresa,
  f.porte,
  f.cargo,
  f.canal,
  f.telefone,
  f.intencao,
  f.lead_score,
  f.score_componentes.intencao     AS sc_intencao,
  f.score_componentes.perfil       AS sc_perfil,
  f.score_componentes.sinais       AS sc_sinais,
  f.score_componentes.recencia     AS sc_recencia,
  f.motivo,
  f.proximo_passo,
  f.produto,
  f.qtd_licencas,
  f.prazo,
  f.orcamento_aprovado,
  f.concorrente_citado,
  f.ja_cliente,
  f.mensagem,
  cast(f.recebido_em AS STRING)    AS recebido_em,
  c.lead_id IS NOT NULL            AS contatado,
  cast(c.contatado_em AS STRING)   AS contatado_em
FROM leadscore.gold.fila_do_dia f
LEFT JOIN contatos c USING (lead_id)
WHERE f.data = (SELECT max(data) FROM leadscore.gold.fila_do_dia)
ORDER BY f.posicao
