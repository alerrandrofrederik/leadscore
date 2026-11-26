export const INTENCAO_ROTULO: Record<string, string> = {
  compra_imediata: 'Compra imediata',
  avaliando: 'Avaliando',
  suporte: 'Suporte',
  spam: 'Spam',
};

/** Classes de token por intenção (verde = comprar, azul = avaliar, âmbar = suporte, vermelho = spam). */
export const INTENCAO_CLASSE: Record<string, string> = {
  compra_imediata: 'bg-success text-success-foreground',
  avaliando: 'bg-primary text-primary-foreground',
  suporte: 'bg-warning text-warning-foreground',
  spam: 'bg-destructive text-destructive-foreground',
};

export const CANAL_ROTULO: Record<string, string> = {
  indicacao: 'Indicação',
  linkedin: 'LinkedIn',
  google_ads: 'Google Ads',
  evento: 'Evento',
  site: 'Site',
};

/** O analytics pode devolver BOOLEAN como texto ("true"/"false"); "false" seria verdadeiro em JS. */
export const bool = (v: boolean | string | null | undefined): boolean => v === true || v === 'true';

export const num =(v: number | string | null | undefined): number => Number(v ?? 0);

export const fmtInt = (v: number | string | null | undefined): string =>
  num(v).toLocaleString('pt-BR', { maximumFractionDigits: 0 });

export const fmtPct = (v: number | string | null | undefined): string =>
  `${num(v).toLocaleString('pt-BR', { maximumFractionDigits: 1 })}%`;

export const fmtDataHora = (v: string | null | undefined): string => {
  if (!v) return '—';
  const d = new Date(v.replace(' ', 'T'));
  return Number.isNaN(d.getTime()) ? v : d.toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' });
};

export const fmtData = (v: string | null | undefined): string => {
  if (!v) return '—';
  const [a, m, d] = v.slice(0, 10).split('-');
  return a && m && d ? `${d}/${m}/${a}` : v;
};
