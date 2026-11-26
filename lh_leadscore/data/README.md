# Lead Score V3 · dados sintéticos (projeto lh_ensaio05)

Gerados por `gerar_csvs.py --data 2026-11-23` (seed fixa), saída em `lead_score_dados/`. Para outro dia:
`python gerar_csvs.py --data AAAA-MM-DD` (mesma estrutura, datas e nomes de arquivo atualizados).

## Onde subir (catálogo `lh_ensaio05`)
| Pasta local | Destino no Volume | Quando |
|---|---|---|
| `lead_score_dados/raw/empresas/` | `/Volumes/lh_ensaio05/landing/raw/empresas/` | antes da demo (pre-flight) |
| `lead_score_dados/raw/historico/` | `/Volumes/lh_ensaio05/landing/raw/historico/` | antes da demo (pre-flight) |
| `lead_score_dados/raw/leads/` | `/Volumes/lh_ensaio05/landing/raw/leads/` | **ao vivo** |
| `lead_score_dados/gabarito/` | `/Volumes/lh_ensaio05/landing/gabarito/` (fora do `raw`) | antes da demo (pre-flight) |

O `scripts/preflight.sh` cria o catálogo, os schemas e os volumes e sobe empresas, histórico e gabarito.

> `data/gabarito/` é de uma geração antiga (2026-11-22, IDs `L20261122-*`) e **não** é usada. O gabarito
> que bate com os CSVs é `lead_score_dados/gabarito/`.

## leads_2026-11-23.csv (100 linhas → 96 leads únicos)
- Após deduplicação: 26 compra_imediata · 36 avaliando · 16 suporte · 18 spam → **6 compras ficam fora da fila de 20**.
- **Mensagem herói** `L20261123-0089`: 200 licenças do Atlas Gestão até dezembro, orçamento aprovado, chega às 17h48.
- **Pegadinhas P1–P5** (coluna `pegadinha` do gabarito).
- Duplicados: 2 reenvios com e-mail em outra caixa/espaços, 1 reenvio que evolui para compra (`L20261123-0064` deve sobreviver), 1 duplo clique.
- CNPJ com/sem máscara e com espaços; 38 vazios; **2 inválidos**.
- **2 datas malformadas** em `recebido_em` (use schema hint `recebido_em TIMESTAMP`).
- 3 mensagens com menos de 5 caracteres.

## Outros
- `empresas_2026-11-23.csv`: 121 empresas · `oportunidades_2026-11-23.csv`: 119 oportunidades.
- `gabarito/intencao.csv`: intenção esperada por linha · `gabarito/entidades.csv`: entidades esperadas das mensagens de compra.

Empresas, pessoas, concorrentes e CNPJs são fictícios.
