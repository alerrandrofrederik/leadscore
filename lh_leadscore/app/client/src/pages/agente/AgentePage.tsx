import { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  AlertDescription,
  Badge,
  Button,
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  GenieChatInput,
  GenieChatMessageList,
  useGenieChat,
} from '@databricks/appkit-ui/react';
import { Bot, Flame, Radio, RotateCcw, Search, Target, UserCheck, type LucideIcon } from 'lucide-react';

/** Perguntas do roteiro da demo (PRD §2.8). */
const ROTEIRO: { titulo: string; pergunta: string; icone: LucideIcon }[] = [
  { titulo: 'Leads quentes de hoje', pergunta: 'Quantos leads de compra imediata chegaram hoje?', icone: Flame },
  { titulo: 'Melhor canal', pergunta: 'Qual canal trouxe mais leads de compra imediata?', icone: Radio },
  { titulo: 'Concorrentes citados', pergunta: 'Quais leads citaram concorrente?', icone: Search },
  { titulo: 'Contatos da fila', pergunta: 'Quantos leads da minha fila eu já contatei?', icone: UserCheck },
  { titulo: 'Quem ficou de fora', pergunta: 'Quais leads de compra imediata ficaram fora da fila de hoje?', icone: Target },
];

function useQuemSouEu() {
  const [email, setEmail] = useState<string | null>(null);
  useEffect(() => {
    fetch('/api/whoami')
      .then((r) => (r.ok ? r.json() : null))
      .then((d: { email?: string | null } | null) => setEmail(d?.email ?? null))
      .catch(() => setEmail(null));
  }, []);
  return email;
}

export function AgentePage() {
  const { messages, status, error, sendMessage, reset } = useGenieChat({ alias: 'default' });
  const email = useQuemSouEu();
  const ocupado = status === 'streaming' || status === 'loading-history';

  const ultimoSql = useMemo(() => {
    for (const m of [...messages].reverse())
      for (const a of m.attachments ?? []) if (a.query?.query) return a.query;
    return null;
  }, [messages]);

  return (
    <div className="mx-auto max-w-7xl space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">
            Inteligência → Agente · AI/BI Genie
          </p>
          <h1 className="mt-2 flex items-center gap-2 text-3xl font-bold tracking-tight">
            <Bot className="h-7 w-7" /> Agente Comercial
          </h1>
          <p className="mt-1 max-w-3xl text-muted-foreground">
            Pergunte em português sobre os leads, a fila e os contatos. O agente consulta as tabelas Gold governadas pelo
            Unity Catalog e mostra o SQL que usou.
          </p>
        </div>
        <Badge variant="secondary">{email ?? 'Usuário do workspace'}</Badge>
      </div>

      <div className="grid gap-6 lg:grid-cols-[320px_1fr]">
        <section className="space-y-3">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">Perguntas do roteiro</p>
          {ROTEIRO.map(({ titulo, pergunta, icone: Icone }) => (
            <Card key={pergunta}>
              <CardHeader className="pb-2">
                <CardTitle className="flex items-center gap-2 text-base">
                  <Icone className="h-4 w-4" /> {titulo}
                </CardTitle>
                <CardDescription>{pergunta}</CardDescription>
              </CardHeader>
              <CardContent>
                <Button size="sm" variant="outline" disabled={ocupado} onClick={() => sendMessage(pergunta)}>
                  Perguntar ao agente
                </Button>
              </CardContent>
            </Card>
          ))}
        </section>

        <section className="space-y-4">
          <Card className="flex h-[min(640px,75vh)] flex-col overflow-hidden">
            <div className="flex items-center justify-between border-b px-4 py-2">
              <p className="text-sm text-muted-foreground">
                {status === 'streaming' ? 'Analisando os dados…' : 'Converse com o agente'}
              </p>
              <Button size="sm" variant="ghost" onClick={reset} disabled={ocupado || messages.length === 0}>
                <RotateCcw className="h-4 w-4" /> Nova conversa
              </Button>
            </div>
            {messages.length === 0 ? (
              <div className="flex flex-1 items-center justify-center p-6 text-center text-sm text-muted-foreground">
                Escolha uma pergunta do roteiro ou digite a sua abaixo.
              </div>
            ) : (
              <GenieChatMessageList messages={messages} status={status} className="flex-1" />
            )}
            <div className="border-t p-3">
              <GenieChatInput onSend={sendMessage} disabled={ocupado} placeholder="Ex.: quais leads da Ana já foram contatados?" />
            </div>
          </Card>

          {status === 'error' && (
            <Alert variant="destructive">
              <AlertDescription>{error ?? 'O agente não conseguiu responder. Reformule ou tente de novo.'}</AlertDescription>
            </Alert>
          )}

          {ultimoSql && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">SQL gerado</CardTitle>
                <CardDescription>{ultimoSql.title ?? 'Como a última resposta foi calculada'}</CardDescription>
              </CardHeader>
              <CardContent>
                <pre className="overflow-auto rounded-md bg-muted p-3 text-xs">{ultimoSql.query}</pre>
              </CardContent>
            </Card>
          )}

          <p className="text-xs text-muted-foreground">
            Resposta gerada por IA (Genie) a partir dos dados: confira o SQL gerado antes de decidir. As consultas rodam
            com as permissões do usuário conectado (on-behalf-of) sobre leadscore.gold.
          </p>
        </section>
      </div>
    </div>
  );
}
