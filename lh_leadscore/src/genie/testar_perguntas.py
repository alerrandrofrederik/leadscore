"""Faz as 5 perguntas do roteiro (PRD §2.8) ao Genie Space e mostra SQL + resultado (T4.5 / CA-11).

Uso:
    python src/genie/testar_perguntas.py <SPACE_ID> [--profile leadscore]
"""

import json
import subprocess
import sys

PERGUNTAS = [
    ("Quantos leads de compra imediata chegaram hoje?", "26"),
    ("Qual canal trouxe mais leads de compra imediata?", "Indicação e LinkedIn"),
    ("Quais leads citaram concorrente?", "lista com o herói (OmniERP)"),
    ("Quantos leads da minha fila eu já contatei?", "depende do que foi marcado"),
    ("Quais leads de compra imediata ficaram fora da fila de hoje?", "6 leads"),
]


def cli(*args: str, profile: str) -> dict:
    out = subprocess.run(
        ["databricks", *args, "--profile", profile, "-o", "json"],
        capture_output=True, text=True, encoding="utf-8", check=True,
    ).stdout
    return json.loads(out)


def main() -> None:
    space_id = sys.argv[1]
    profile = sys.argv[sys.argv.index("--profile") + 1] if "--profile" in sys.argv else "leadscore"
    for pergunta, esperado in PERGUNTAS:
        msg = cli("genie", "start-conversation", space_id, pergunta, profile=profile)
        print(f"\n### {pergunta}\nesperado: {esperado} · status: {msg.get('status')}")
        for att in msg.get("attachments") or []:
            if att.get("text"):
                print("texto:", att["text"].get("content", "")[:300])
            if att.get("query"):
                print("sql:", " ".join(att["query"].get("query", "").split())[:400])
                res = cli(
                    "genie", "get-message-attachment-query-result",
                    space_id, msg["conversation_id"], msg["message_id"], att["attachment_id"],
                    profile=profile,
                )
                st = res.get("statement_response", {})
                rows = (st.get("result") or {}).get("data_array") or []
                print(f"linhas: {len(rows)} →", rows[:8])


if __name__ == "__main__":
    main()
