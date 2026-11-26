import { Link } from 'react-router';
import {
  Alert,
  AlertDescription,
  AlertTitle,
  BarChart,
  Button,
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
  Skeleton,
  useAnalyticsQuery,
} from '@databricks/appkit-ui/react';
import { ArrowRight, CheckCircle2, Flame, Inbox, ListOrdered, Sparkles, Target } from 'lucide-react';
import type { ComponentType } from 'react';
import { useParametros } from '../../lib/atualizacao';
import { fmtData, fmtDataHora, fmtInt, fmtPct, num } from '../../lib/formatters';

function Kpi({
  titulo,
  valor,
  detalhe,
  fonte,
  icone: Icone,
}: {
  titulo: string;
  valor: string;
  detalhe: string;
  fonte: string;
  icone: ComponentType<{ className?: string }>;
}) {
  return (
    <Card className="border-l-4 border-l-primary">
      <CardHeader className="pb-2">
        <CardDescription className="flex items-center justify-between">
          {titulo}
          <Icone className="h-4 w-4" />
        </CardDescription>
        <CardTitle className="text-3xl tabular-nums">{valor}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <p className="text-xs text-muted-foreground">{detalhe}</p>
        <p className="font-mono text-[10px] uppercase tracking-wider text-muted-foreground">{fonte}</p>
      </CardContent>
    </Card>
  );
}

function Funil() {
  const parametros = useParametros();
  const { data, loading, error } = useAnalyticsQuery('funil_dia', parametros);
  if (loading && !data) return <Skeleton className="h-48 w-full" />;
  if (error) return <Alert variant="destructive"><AlertDescription>{error}</AlertDescription></Alert>;
  if (!data?.length) return <p className="text-sm text-muted-foreground">Sem dados do funil hoje.</p>;
  const topo = Math.max(...data.map((e) => num(e.leads)), 1);
  return (
    <ol className="space-y-4">
      {data.map((etapa) => (
        <li key={etapa.ordem} className="space-y-1.5">
          <div className="flex items-baseline justify-between text-sm">
            <span className="font-medium">{etapa.etapa}</span>
            <span className="tabular-nums font-semibold">{fmtInt(etapa.leads)}</span>
          </div>
          <div className="h-3 rounded-full bg-muted">
            <div
              className="h-3 rounded-full bg-primary transition-all"
              style={{ width: `${Math.max(2, (num(etapa.leads) / topo) * 100)}%` }}
            />
          </div>
          <p className="text-xs text-muted-foreground">{etapa.detalhe}</p>
        </li>
      ))}
    </ol>
  );
}

export function GestorPage() {
  const parametros = useParametros();
  const { data, loading, error } = useAnalyticsQuery('resumo_dia', parametros);
  const r = data?.[0];

  return (
    <div className="mx-auto max-w-7xl space-y-8">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">
          Operação comercial · dia de referência {r ? fmtData(r.data) : '…'}
        </p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight">Visão do Gestor</h1>
      </div>

      {error && (
        <Alert variant="destructive">
          <AlertTitle>Não foi possível carregar o resumo do dia</AlertTitle>
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {loading && !r ? (
        <Skeleton className="h-52 w-full rounded-2xl" />
      ) : r && num(r.recebidos) > 0 ? (
        <section className="rounded-2xl bg-primary p-8 text-primary-foreground shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] opacity-80">
            {fmtInt(r.recebidos)} leads · 20 conversas · quais 20?
          </p>
          <h2 className="mt-3 text-3xl font-bold md:text-4xl">
            {fmtInt(r.na_fila)} leads na fila hoje · {fmtInt(r.compra_imediata)} de compra imediata
          </h2>
          <p className="mt-4 max-w-3xl text-base opacity-90">
            De <strong>{fmtInt(r.recebidos)}</strong> leads recebidos ({fmtInt(r.unicos)} únicos), a IA classificou a
            intenção e extraiu produto, licenças, prazo e orçamento. A fila reúne as <strong>{fmtInt(r.na_fila)}</strong>{' '}
            maiores notas; <strong>{fmtInt(r.compra_fora_fila)}</strong> leads de compra imediata ficaram de fora por falta
            de capacidade e <strong>{fmtInt(r.contatados)}</strong> já foram contatados.
          </p>
          <div className="mt-6 flex flex-wrap gap-3">
            <Button asChild variant="secondary">
              <Link to="/fila">
                Ver minha fila <ArrowRight className="h-4 w-4" />
              </Link>
            </Button>
            <Button asChild variant="outline" className="border-primary-foreground/40 bg-transparent text-primary-foreground hover:bg-primary-foreground/10">
              <Link to="/agente">
                <Sparkles className="h-4 w-4" /> Perguntar ao agente
              </Link>
            </Button>
          </div>
        </section>
      ) : (
        !error && (
          <Empty>
            <EmptyHeader>
              <EmptyTitle>Nenhum lead processado ainda</EmptyTitle>
              <EmptyDescription>
                Suba o CSV do dia em /Volumes/leadscore/landing/raw/leads/ e rode o pipeline lh_leadscore_pipeline.
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        )
      )}

      {r && num(r.recebidos) > 0 && (
        <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
          <Kpi titulo="Recebidos" valor={fmtInt(r.recebidos)} detalhe={`${fmtInt(r.unicos)} únicos após deduplicação`} fonte="silver.leads_normalizados" icone={Inbox} />
          <Kpi titulo="Classificados" valor={fmtInt(r.classificados)} detalhe="ai_classify + regra de mensagem curta" fonte="gold.leads_ia" icone={Sparkles} />
          <Kpi titulo="Na fila" valor={fmtInt(r.na_fila)} detalhe="capacidade: 4 vendedores × 5" fonte="gold.fila_do_dia" icone={ListOrdered} />
          <Kpi titulo="Contatados" valor={fmtInt(r.contatados)} detalhe={`de ${fmtInt(r.na_fila)} leads na fila`} fonte="gold.feedback_contatos" icone={CheckCircle2} />
          <Kpi titulo="Compra imediata" valor={fmtInt(r.compra_imediata)} detalhe={`${fmtInt(r.compra_fora_fila)} ficaram fora da fila`} fonte="gold.leads_classificados" icone={Flame} />
          <Kpi titulo="Acurácia da IA" valor={r.acuracia_ia_pct == null ? '—' : fmtPct(r.acuracia_ia_pct)} detalhe="vs. gabarito · meta ≥ 85%" fonte="gabarito/intencao.csv" icone={Target} />
        </section>
      )}

      <section className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Funil do dia</CardTitle>
            <CardDescription>Recebidos → classificados → na fila → contatados</CardDescription>
          </CardHeader>
          <CardContent>
            <Funil />
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Intenção por canal</CardTitle>
            <CardDescription>Indicação e LinkedIn concentram compra imediata; Google Ads, spam</CardDescription>
          </CardHeader>
          <CardContent>
            <BarChart
              queryKey="intencao_por_canal"
              parameters={parametros}
              xKey="canal"
              yKey={['compra_imediata', 'avaliando', 'suporte', 'spam']}
              stacked
              colorPalette="categorical"
              height={300}
            />
          </CardContent>
        </Card>
      </section>

      {r && (
        <p className="text-xs text-muted-foreground">
          Fonte: catálogo leadscore (Unity Catalog) · IA processada em {fmtDataHora(r.processado_em)} · atualiza a cada minuto.
        </p>
      )}
    </div>
  );
}
