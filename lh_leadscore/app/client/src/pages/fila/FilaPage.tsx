import { useMemo, useState } from 'react';
import {
  Alert,
  AlertDescription,
  AlertTitle,
  Badge,
  Button,
  Card,
  CardContent,
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  Skeleton,
  useAnalyticsQuery,
} from '@databricks/appkit-ui/react';
import { Building2, Check, ListOrdered, PhoneCall, Quote } from 'lucide-react';
import { useAtualizacao, useParametros } from '../../lib/atualizacao';
import { CANAL_ROTULO, INTENCAO_CLASSE, INTENCAO_ROTULO, bool, fmtDataHora, fmtInt, num } from '../../lib/formatters';

type Lead = NonNullable<ReturnType<typeof useFila>['data']>[number];

function useFila() {
  const parametros = useParametros();
  return useAnalyticsQuery('fila_do_dia', parametros);
}

const TODOS = 'todos';

const COMPONENTES = [
  { chave: 'sc_intencao', rotulo: 'Intenção', peso: '50%' },
  { chave: 'sc_perfil', rotulo: 'Perfil', peso: '25%' },
  { chave: 'sc_sinais', rotulo: 'Sinais', peso: '15%' },
  { chave: 'sc_recencia', rotulo: 'Recência', peso: '10%' },
] as const;

function Entidade({ rotulo, valor }: { rotulo: string; valor: string | number | null | undefined }) {
  if (valor === null || valor === undefined || valor === '') return null;
  return (
    <span className="rounded-md bg-muted px-2 py-1 text-xs">
      <span className="text-muted-foreground">{rotulo}:</span> <strong>{valor}</strong>
    </span>
  );
}

function CardLead({ lead, contatadoLocal, onContatar }: { lead: Lead; contatadoLocal: boolean; onContatar: (l: Lead) => Promise<void> }) {
  const [enviando, setEnviando] = useState(false);
  const [erro, setErro] = useState<string | null>(null);
  const contatado = bool(lead.contatado) || contatadoLocal;

  const marcar = async () => {
    setEnviando(true);
    setErro(null);
    try {
      await onContatar(lead);
    } catch (e) {
      setErro(e instanceof Error ? e.message : 'Falha ao registrar o contato.');
    } finally {
      setEnviando(false);
    }
  };

  return (
    <Card>
      <CardContent className="grid gap-6 p-6 lg:grid-cols-[1fr_280px]">
        <div className="min-w-0 space-y-4">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm text-muted-foreground">#{lead.posicao}</span>
            <h3 className="text-xl font-semibold">{lead.nome}</h3>
            <Badge className={INTENCAO_CLASSE[lead.intencao] ?? ''}>{INTENCAO_ROTULO[lead.intencao] ?? lead.intencao}</Badge>
            <Badge variant="secondary">{lead.vendedor}</Badge>
            {contatado && (
              <Badge className="bg-success text-success-foreground">
                <Check className="h-3 w-3" /> Contatado
              </Badge>
            )}
          </div>
          <p className="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-muted-foreground">
            <span className="flex items-center gap-1">
              <Building2 className="h-4 w-4" />
              {lead.empresa ?? 'Empresa não identificada'}
              {lead.porte && lead.porte !== 'desconhecido' ? ` · ${lead.porte}` : ''}
            </span>
            {lead.cargo && <span>{lead.cargo}</span>}
            <span>canal: {CANAL_ROTULO[lead.canal] ?? lead.canal}</span>
            {lead.telefone && <span>{lead.telefone}</span>}
          </p>
          <p className="font-medium">{lead.motivo}</p>
          <div className="flex flex-wrap gap-2">
            <Entidade rotulo="Produto" valor={lead.produto} />
            <Entidade rotulo="Licenças" valor={lead.qtd_licencas} />
            <Entidade rotulo="Prazo" valor={lead.prazo} />
            <Entidade rotulo="Orçamento" valor={bool(lead.orcamento_aprovado) ? 'aprovado' : null} />
            <Entidade rotulo="Concorrente" valor={lead.concorrente_citado} />
          </div>
          <blockquote className="flex gap-3 rounded-lg bg-muted/60 p-4 text-sm text-muted-foreground">
            <Quote className="h-4 w-4 shrink-0" />
            <span>{lead.mensagem}</span>
          </blockquote>
          <p className="text-xs text-muted-foreground">Recebido em {fmtDataHora(lead.recebido_em)} · {lead.lead_id}</p>
        </div>

        <div className="space-y-4 lg:border-l lg:pl-6">
          <div>
            <p className="text-sm text-muted-foreground">Nota de prioridade</p>
            <p className="text-5xl font-bold tabular-nums">{fmtInt(lead.lead_score)}</p>
          </div>
          <div className="space-y-2.5">
            {COMPONENTES.map((c) => (
              <div key={c.chave} className="space-y-1">
                <div className="flex justify-between text-xs">
                  <span className="text-muted-foreground">
                    {c.rotulo} ({c.peso})
                  </span>
                  <span className="tabular-nums">{fmtInt(lead[c.chave])}</span>
                </div>
                <div className="h-1.5 rounded-full bg-muted">
                  <div className="h-1.5 rounded-full bg-foreground/70" style={{ width: `${num(lead[c.chave])}%` }} />
                </div>
              </div>
            ))}
          </div>
          <div className="rounded-lg bg-primary/10 p-3 text-sm">
            <strong>Próximo passo:</strong> {lead.proximo_passo}
          </div>
          <Button className="w-full" variant={contatado ? 'outline' : 'default'} disabled={contatado || enviando} onClick={() => void marcar()}>
            <PhoneCall className="h-4 w-4" />
            {contatado ? 'Contatado' : enviando ? 'Registrando…' : 'Marcar como contatado'}
          </Button>
          {erro && <p className="text-xs text-destructive">{erro}</p>}
        </div>
      </CardContent>
    </Card>
  );
}

export function FilaPage() {
  const { data, loading, error } = useFila();
  const { renovar } = useAtualizacao();
  const [vendedor, setVendedor] = useState<string>(TODOS);
  const [contatadosLocais, setContatadosLocais] = useState<Set<string>>(new Set());

  const vendedores = useMemo(() => [...new Set((data ?? []).map((l) => l.vendedor))].sort(), [data]);
  const leads = useMemo(
    () => (data ?? []).filter((l) => vendedor === TODOS || l.vendedor === vendedor),
    [data, vendedor],
  );
  const totalContatados = (data ?? []).filter((l) => bool(l.contatado) || contatadosLocais.has(l.lead_id)).length;

  const contatar = async (lead: Lead) => {
    const resp = await fetch('/api/contatos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ lead_id: lead.lead_id, vendedor: lead.vendedor, resultado: 'contatado' }),
    });
    if (!resp.ok) {
      const corpo = (await resp.json().catch(() => null)) as { error?: string } | null;
      throw new Error(corpo?.error ?? `Erro ${resp.status} ao registrar o contato.`);
    }
    setContatadosLocais((s) => new Set(s).add(lead.lead_id));
    renovar();
  };

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">Operação → Fila do Dia</p>
        <h1 className="mt-2 flex items-center gap-2 text-3xl font-bold tracking-tight">
          <ListOrdered className="h-7 w-7" /> Fila do Dia
        </h1>
        <p className="mt-1 text-muted-foreground">
          Os 20 leads de maior nota, 5 por vendedor. Cada card mostra por que o lead está na fila e o que fazer na ligação.
        </p>
      </div>

      <div className="flex flex-wrap items-end gap-6">
        <div className="space-y-1.5">
          <p className="text-sm font-medium">Vendedor</p>
          <Select value={vendedor} onValueChange={setVendedor}>
            <SelectTrigger className="w-56">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={TODOS}>Todos os vendedores</SelectItem>
              {vendedores.map((v) => (
                <SelectItem key={v} value={v}>
                  {v}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        {data && (
          <p className="pb-2 text-sm text-muted-foreground">
            {totalContatados} de {data.length} contatados
          </p>
        )}
      </div>

      {error && (
        <Alert variant="destructive">
          <AlertTitle>Não foi possível carregar a fila</AlertTitle>
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {loading && !data ? (
        <div className="space-y-4">
          {[0, 1, 2].map((i) => (
            <Skeleton key={i} className="h-64 w-full rounded-xl" />
          ))}
        </div>
      ) : leads.length === 0 && !error ? (
        <Empty>
          <EmptyHeader>
            <EmptyTitle>Fila vazia</EmptyTitle>
            <EmptyDescription>Ainda não há leads priorizados para hoje. Rode o pipeline após subir o CSV do dia.</EmptyDescription>
          </EmptyHeader>
        </Empty>
      ) : (
        <div className="space-y-4">
          {leads.map((lead) => (
            <CardLead key={lead.lead_id} lead={lead} contatadoLocal={contatadosLocais.has(lead.lead_id)} onContatar={contatar} />
          ))}
        </div>
      )}
    </div>
  );
}
