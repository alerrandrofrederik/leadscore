import { createBrowserRouter, NavLink, Outlet, RouterProvider } from 'react-router';
import { useEffect, useState } from 'react';
import {
  Badge,
  Button,
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  useIsMobile,
} from '@databricks/appkit-ui/react';
import { Bot, LayoutDashboard, ListOrdered, Menu, Moon, PhoneCall, Sun } from 'lucide-react';
import { AtualizacaoProvider } from './lib/atualizacao';
import { GestorPage } from './pages/gestor/GestorPage';
import { FilaPage } from './pages/fila/FilaPage';
import { AgentePage } from './pages/agente/AgentePage';

const NAV = [
  { secao: 'Operação', to: '/', end: true, icone: LayoutDashboard, titulo: 'Visão do Gestor', sub: 'Funil · Intenção · Canal' },
  { secao: 'Operação', to: '/fila', icone: ListOrdered, titulo: 'Fila do Dia', sub: '20 leads · 5 por vendedor' },
  { secao: 'Inteligência', to: '/agente', icone: Bot, titulo: 'Agente', sub: 'AI/BI Genie' },
] as const;

const linkClasse = ({ isActive }: { isActive: boolean }) =>
  `flex items-start gap-3 rounded-lg px-3 py-2.5 transition-colors ${
    isActive
      ? 'bg-sidebar-accent text-sidebar-accent-foreground'
      : 'text-sidebar-foreground/80 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground'
  }`;

function Navegacao({ onNavigate }: { onNavigate?: () => void }) {
  const secoes = [...new Set(NAV.map((n) => n.secao))];
  return (
    <nav className="flex flex-col gap-6">
      {secoes.map((secao) => (
        <div key={secao} className="flex flex-col gap-1">
          <p className="px-3 text-xs font-semibold uppercase tracking-widest text-sidebar-foreground/60">{secao}</p>
          {NAV.filter((n) => n.secao === secao).map(({ to, icone: Icone, titulo, sub, ...rest }) => (
            <NavLink key={to} to={to} end={'end' in rest} className={linkClasse} onClick={onNavigate}>
              <Icone className="mt-0.5 h-4 w-4 shrink-0" />
              <span>
                <span className="block text-sm font-medium">{titulo}</span>
                <span className="block text-xs opacity-70">{sub}</span>
              </span>
            </NavLink>
          ))}
        </div>
      ))}
    </nav>
  );
}

function Marca() {
  return (
    <div className="flex items-center gap-3 px-1">
      <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-sidebar-primary text-sidebar-primary-foreground">
        <PhoneCall className="h-5 w-5" />
      </div>
      <div>
        <p className="font-semibold leading-tight">Lead Score</p>
        <p className="text-xs opacity-70">Atlas Software · Comercial</p>
      </div>
    </div>
  );
}

function useTema() {
  const [escuro, setEscuro] = useState(() => {
    const salvo = localStorage.getItem('leadscore:tema');
    return salvo ? salvo === 'escuro' : window.matchMedia('(prefers-color-scheme: dark)').matches;
  });
  useEffect(() => {
    document.documentElement.classList.toggle('dark', escuro);
    document.documentElement.classList.toggle('light', !escuro);
    localStorage.setItem('leadscore:tema', escuro ? 'escuro' : 'claro');
  }, [escuro]);
  return { escuro, alternar: () => setEscuro((e) => !e) };
}

function Sidebar({ onNavigate }: { onNavigate?: () => void }) {
  const { escuro, alternar } = useTema();
  return (
    <div className="flex h-full flex-col gap-8 bg-sidebar p-5 text-sidebar-foreground">
      <Marca />
      <Navegacao onNavigate={onNavigate} />
      <div className="mt-auto flex flex-col gap-4">
        <p className="px-1 text-xs text-sidebar-foreground/60">
          SQL Warehouse · Genie · AI Functions · Unity Catalog
        </p>
        <Button
          variant="outline"
          className="border-sidebar-border bg-transparent text-sidebar-foreground hover:bg-sidebar-accent"
          onClick={alternar}
        >
          {escuro ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
          {escuro ? 'Tema claro' : 'Tema escuro'}
        </Button>
      </div>
    </div>
  );
}

function Layout() {
  const isMobile = useIsMobile();
  const [aberto, setAberto] = useState(false);
  return (
    <div className="flex min-h-screen bg-background">
      <aside className="hidden w-72 shrink-0 md:block">
        <div className="sticky top-0 h-screen">
          <Sidebar />
        </div>
      </aside>
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center gap-3 border-b px-4 py-3 md:px-8">
          <Sheet open={aberto && isMobile} onOpenChange={setAberto}>
            <Button variant="ghost" size="icon" className="md:hidden" onClick={() => setAberto(true)}>
              <Menu className="h-5 w-5" />
              <span className="sr-only">Abrir navegação</span>
            </Button>
            <SheetContent side="left" className="w-72 p-0">
              <SheetHeader className="sr-only">
                <SheetTitle>Navegação</SheetTitle>
              </SheetHeader>
              <Sidebar onNavigate={() => setAberto(false)} />
            </SheetContent>
          </Sheet>
          <Badge variant="outline" className="ml-auto">
            Demo · dados 100% sintéticos
          </Badge>
        </header>
        <main className="flex-1 px-4 py-6 md:px-8 md:py-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

const router = createBrowserRouter([
  {
    element: <Layout />,
    children: [
      { path: '/', element: <GestorPage /> },
      { path: '/fila', element: <FilaPage /> },
      { path: '/agente', element: <AgentePage /> },
    ],
  },
]);

export default function App() {
  return (
    <AtualizacaoProvider>
      <RouterProvider router={router} />
    </AtualizacaoProvider>
  );
}
