import { describe, expect, it } from 'vitest';
import { INSERT_CONTATO, contatoSchema, parametrosContato } from './contato';

describe('contatoSchema', () => {
  it('aceita um contato válido e aplica o resultado padrão', () => {
    const r = contatoSchema.parse({ lead_id: 'L20261123-0089', vendedor: 'Bruno' });
    expect(r).toEqual({ lead_id: 'L20261123-0089', vendedor: 'Bruno', resultado: 'contatado' });
  });

  it('rejeita lead_id fora do padrão (evita injeção e lixo)', () => {
    expect(contatoSchema.safeParse({ lead_id: "x'; DROP TABLE t; --", vendedor: 'Ana' }).success).toBe(false);
  });

  it('rejeita vendedor vazio', () => {
    expect(contatoSchema.safeParse({ lead_id: 'L20261123-0001', vendedor: '  ' }).success).toBe(false);
  });
});

describe('INSERT_CONTATO', () => {
  it('usa só parâmetros nomeados e grava apenas leads da fila', () => {
    expect(INSERT_CONTATO).toContain(':lead_id');
    expect(INSERT_CONTATO).toContain('leadscore.gold.fila_do_dia');
    const nomes = parametrosContato({ lead_id: 'L20261123-0089', vendedor: 'Bruno', resultado: 'contatado' }).map((p) => p.name);
    expect(nomes).toEqual(['lead_id', 'vendedor', 'resultado']);
  });
});
