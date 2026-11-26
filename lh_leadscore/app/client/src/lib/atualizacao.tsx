import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { sql } from '@databricks/appkit-ui/js';

/**
 * As queries do analytics ficam em cache no servidor (chave = query + parâmetros).
 * `atualizacao` entra como parâmetro: muda a cada minuto (leads novos aparecem rápido, SLA ≤ 15 min)
 * e a cada contato marcado (o funil e a fila refletem o clique na hora).
 */
interface AtualizacaoCtx {
  chave: string;
  renovar: () => void;
}

const Ctx = createContext<AtualizacaoCtx | null>(null);

const minutoAtual = () => Math.floor(Date.now() / 60_000);

export function AtualizacaoProvider({ children }: { children: ReactNode }) {
  const [minuto, setMinuto] = useState(minutoAtual);
  const [contador, setContador] = useState(0);

  useEffect(() => {
    const id = window.setInterval(() => setMinuto(minutoAtual()), 15_000);
    return () => window.clearInterval(id);
  }, []);

  const renovar = useCallback(() => setContador((c) => c + 1), []);
  const valor = useMemo(() => ({ chave: `${minuto}-${contador}`, renovar }), [minuto, contador, renovar]);
  return <Ctx.Provider value={valor}>{children}</Ctx.Provider>;
}

export function useAtualizacao() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('useAtualizacao precisa de AtualizacaoProvider');
  return ctx;
}

/** Parâmetros padrão das queries do app. */
export function useParametros() {
  const { chave } = useAtualizacao();
  return useMemo(() => ({ atualizacao: sql.string(chave) }), [chave]);
}
