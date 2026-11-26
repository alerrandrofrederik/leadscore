"""Gera o serialized_space do Genie Space "Lead Score · Agente Comercial" (T4.5, RF-16).

Uso:
    python src/genie/gerar_space.py > src/genie/lead_score_space.json
    databricks genie create-space <WAREHOUSE_ID> "$(cat src/genie/lead_score_space.json)" \
        --title "Lead Score · Agente Comercial" --profile leadscore

As perguntas e SQLs de exemplo são as do roteiro da demo (PRD §2.8).
"""

import json
from itertools import count

_seq = count(1)


def _id() -> str:
    # IDs de 32 caracteres hex, crescentes (o Genie exige ordem estável nas listas)
    return f"01f1000000000000000000000000{next(_seq):04x}"


def _linhas(txt: str) -> list[str]:
    linhas = txt.strip("\n").split("\n")
    return [l + "\n" for l in linhas[:-1]] + [linhas[-1]]


CAT = "leadscore.gold"

INSTRUCOES = """\
* Responda sempre em português do Brasil.
* "Hoje" ou "do dia" significa o dia do arquivo de leads mais recente: data_arquivo = (SELECT max(data_arquivo) FROM leadscore.gold.leads_classificados). Na fila, use a coluna data.
* Intenções possíveis (coluna intencao): compra_imediata, avaliando, suporte, spam. "Compra imediata" = intencao = 'compra_imediata'.
* leads_classificados tem todos os leads únicos do dia (um por e-mail). fila_do_dia tem os 20 leads priorizados, 5 por vendedor (Ana, Bruno, Carla, Diego).
* "Ficou fora da fila" = está em leads_classificados e o lead_id não está em fila_do_dia.
* Canais (coluna canal): site, linkedin, evento, indicacao, google_ads. Mostre indicacao como "Indicação" e linkedin como "LinkedIn".
* "Citou concorrente" = concorrente_citado IS NOT NULL.
* "Contatado" = existe registro em feedback_contatos para o lead_id. "Minha fila" se refere ao vendedor citado na pergunta; se não houver, agrupe por vendedor.
* lead_score vai de 0 a 100; score_componentes mostra intencao, perfil, sinais e recencia. Ao listar leads, traga nome, empresa, lead_score e motivo.
"""

EXEMPLOS = [
    (
        "Quantos leads de compra imediata chegaram hoje?",
        f"""SELECT count(*) AS leads_compra_imediata
FROM {CAT}.leads_classificados
WHERE intencao = 'compra_imediata'
  AND data_arquivo = (SELECT max(data_arquivo) FROM {CAT}.leads_classificados)""",
    ),
    (
        "Qual canal trouxe mais leads de compra imediata?",
        f"""SELECT canal, count(*) AS leads_compra_imediata
FROM {CAT}.leads_classificados
WHERE intencao = 'compra_imediata'
  AND data_arquivo = (SELECT max(data_arquivo) FROM {CAT}.leads_classificados)
GROUP BY canal
ORDER BY leads_compra_imediata DESC""",
    ),
    (
        "Quais leads citaram concorrente?",
        f"""SELECT nome, empresa, concorrente_citado, intencao, lead_score, motivo
FROM {CAT}.leads_classificados
WHERE concorrente_citado IS NOT NULL
ORDER BY lead_score DESC""",
    ),
    (
        "Quantos leads da minha fila eu já contatei?",
        f"""SELECT f.vendedor,
       count(*) AS leads_na_fila,
       count(DISTINCT fc.lead_id) AS contatados
FROM {CAT}.fila_do_dia f
LEFT JOIN {CAT}.feedback_contatos fc ON fc.lead_id = f.lead_id
GROUP BY f.vendedor
ORDER BY f.vendedor""",
    ),
    (
        "Quais leads de compra imediata ficaram fora da fila de hoje?",
        f"""SELECT c.nome, c.empresa, c.canal, c.lead_score, c.motivo
FROM {CAT}.leads_classificados c
WHERE c.intencao = 'compra_imediata'
  AND c.data_arquivo = (SELECT max(data_arquivo) FROM {CAT}.leads_classificados)
  AND c.lead_id NOT IN (SELECT lead_id FROM {CAT}.fila_do_dia)
ORDER BY c.lead_score DESC""",
    ),
]

space = {
    "version": 2,
    "config": {
        "sample_questions": [{"id": _id(), "question": [q]} for q, _ in EXEMPLOS],
    },
    "data_sources": {
        "tables": [
            {"identifier": f"{CAT}.feedback_contatos"},
            {"identifier": f"{CAT}.fila_do_dia"},
            {"identifier": f"{CAT}.leads_classificados"},
        ]
    },
    "instructions": {
        "text_instructions": [{"id": _id(), "content": _linhas(INSTRUCOES)}],
        "example_question_sqls": [{"id": _id(), "question": [q], "sql": _linhas(sql)} for q, sql in EXEMPLOS],
    },
}

print(json.dumps(space, ensure_ascii=False, indent=2))
