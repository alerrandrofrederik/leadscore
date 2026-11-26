import { z } from 'zod';

/** Corpo do POST /api/contatos (RF-14). */
export const contatoSchema = z.object({
  lead_id: z.string().regex(/^L\d{8}-\d{4}$/),
  vendedor: z.string().trim().min(1).max(60),
  resultado: z.string().trim().min(1).max(40).default('contatado'),
});

export type Contato = z.infer<typeof contatoSchema>;

/** Só grava contato de lead que está na Fila do Dia; parâmetros nomeados, nunca concatenação. */
export const INSERT_CONTATO = `
  INSERT INTO leadscore.gold.feedback_contatos (lead_id, vendedor, contatado_em, resultado)
  SELECT :lead_id, :vendedor, current_timestamp(), :resultado
  WHERE EXISTS (SELECT 1 FROM leadscore.gold.fila_do_dia WHERE lead_id = :lead_id)
`;

export function parametrosContato(c: Contato) {
  return [
    { name: 'lead_id', value: c.lead_id, type: 'STRING' },
    { name: 'vendedor', value: c.vendedor, type: 'STRING' },
    { name: 'resultado', value: c.resultado, type: 'STRING' },
  ];
}
