"""Critérios de aceite do PRD (CA-01..CA-09) contra as tabelas publicadas no catálogo leadscore.

Rodar apontando para o workspace do projeto:
    DATABRICKS_CONFIG_PROFILE=leadscore uv run pytest tests/test_aceite.py
"""

import pytest

CAT = "leadscore"
HEROI = "L20261123-0089"


def _um(spark, sql):
    return spark.sql(sql).collect()[0][0]


def test_ca01_bronze_100_leads(spark):
    assert _um(spark, f"SELECT count(*) FROM {CAT}.bronze.leads_raw") == 100


def test_ca02_datas_malformadas_resgatadas(spark):
    assert _um(spark, f"SELECT count(*) FROM {CAT}.bronze.leads_raw WHERE _rescued_data IS NOT NULL") == 2


def test_ca03_silver_sem_duplicados(spark):
    row = spark.sql(f"SELECT count(*) n, count(DISTINCT email) e FROM {CAT}.silver.leads").collect()[0]
    assert (row.n, row.e) == (96, 96)
    assert _um(spark, f"SELECT count_if(cnpj_valido = false) FROM {CAT}.silver.leads_normalizados") == 2


def test_ca04_reenvio_que_evolui_mantem_compra(spark):
    assert _um(spark, f"SELECT count(*) FROM {CAT}.silver.leads WHERE lead_id = 'L20261123-0064'") == 1
    assert _um(spark, f"SELECT count(*) FROM {CAT}.silver.leads WHERE lead_id = 'L20261123-0025'") == 0


@pytest.fixture()
def comparacao(spark):
    return spark.sql(f"""
        SELECT g.lead_id, g.pegadinha, g.intencao_esperada = ia.intencao AS acertou
        FROM read_files('/Volumes/{CAT}/landing/gabarito/intencao.csv', format => 'csv', header => true) g
        JOIN {CAT}.gold.leads_ia ia USING (lead_id)
    """)


def test_ca05_acuracia_ai_classify(comparacao):
    rows = comparacao.collect()
    assert len(rows) == 100
    assert sum(r.acertou for r in rows) / len(rows) >= 0.85


def test_ca06_pegadinhas(comparacao):
    pegadinhas = [r for r in comparacao.collect() if r.pegadinha]
    assert len(pegadinhas) == 5
    assert sum(r.acertou for r in pegadinhas) >= 4


def test_ca07_entidades_do_heroi(spark):
    r = spark.sql(f"SELECT * FROM {CAT}.gold.leads_classificados WHERE lead_id = '{HEROI}'").collect()[0]
    assert (r.produto, r.qtd_licencas, r.prazo, r.orcamento_aprovado, r.cargo, r.concorrente_citado) == (
        "Atlas Gestão", 200, "dezembro", True, "Diretor Financeiro", "OmniERP",
    )


def test_ca08_sem_spam_ou_suporte_na_fila(spark):
    assert _um(spark, f"SELECT count_if(intencao IN ('spam','suporte')) FROM {CAT}.gold.fila_do_dia") == 0


def test_ca09_fila_do_dia(spark):
    fila = spark.sql(f"SELECT * FROM {CAT}.gold.fila_do_dia ORDER BY posicao").collect()
    assert len(fila) == 20
    por_vendedor = {}
    for r in fila:
        por_vendedor[r.vendedor] = por_vendedor.get(r.vendedor, 0) + 1
        c = r.score_componentes
        assert None not in (c.intencao, c.perfil, c.sinais, c.recencia)
    assert sorted(por_vendedor.values()) == [5, 5, 5, 5]
    scores = [r.lead_score for r in fila]
    assert scores == sorted(scores, reverse=True)
    assert HEROI in [r.lead_id for r in fila[:3]]


def test_seis_compras_fora_da_fila(spark):
    assert _um(spark, f"""
        SELECT count(*) FROM {CAT}.gold.leads_classificados
        WHERE intencao = 'compra_imediata'
          AND lead_id NOT IN (SELECT lead_id FROM {CAT}.gold.fila_do_dia)
    """) == 6
