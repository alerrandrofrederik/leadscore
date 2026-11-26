import { analytics, createApp, genie, getExecutionContext, getWarehouseId, server } from '@databricks/appkit';
import { INSERT_CONTATO, contatoSchema, parametrosContato } from './contato';

await createApp({
  plugins: [analytics(), genie(), server()],
  onPluginsReady(appkit) {
    appkit.server.extend((app) => {
      // Identidade de quem está usando o app (cabeçalhos injetados pelo Databricks Apps).
      app.get('/api/whoami', (req, res) => {
        res.json({
          email: req.header('x-forwarded-email') ?? null,
          user: req.header('x-forwarded-user') ?? null,
        });
      });

      // RF-14 · "Marcar como contatado" grava em leadscore.gold.feedback_contatos (Delta, lido pelo Genie e pelo gestor).
      app.post('/api/contatos', async (req, res) => {
        const parsed = contatoSchema.safeParse(req.body);
        if (!parsed.success) {
          res.status(400).json({ error: 'Dados inválidos para registrar o contato.' });
          return;
        }
        try {
          const { client } = getExecutionContext();
          const resposta = await client.statementExecution.executeStatement({
            warehouse_id: await getWarehouseId(),
            statement: INSERT_CONTATO,
            parameters: parametrosContato(parsed.data),
            wait_timeout: '30s',
          });
          const estado = resposta.status?.state;
          if (estado !== 'SUCCEEDED') {
            res.status(502).json({ error: `Não foi possível registrar o contato (${estado ?? 'sem status'}).` });
            return;
          }
          res.status(201).json({ ok: true, ...parsed.data, contatado_em: new Date().toISOString() });
        } catch (erro) {
          console.error('Falha ao registrar contato', erro);
          res.status(500).json({ error: 'Falha ao registrar o contato no Databricks.' });
        }
      });
    });
  },
});
