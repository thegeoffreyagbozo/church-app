// Public keepalive / health endpoint (config: verify_jwt = false).
//
// WHY: Supabase free projects pause after ~7 days idle, which would stop sync, reminders,
// and (later) the payments webhook. An internal cron cannot keep a PAUSED project awake, so an
// EXTERNAL pinger (see .github/workflows/keepalive.yml) hits this daily. The DB touch below
// makes the ping count as real activity. (ADR / ARCHITECTURE.md → "operational must-dos".)
import { createClient } from 'jsr:@supabase/supabase-js@2';

Deno.serve(async (_req: Request) => {
  const started = Date.now();
  let db: 'ok' | 'error' = 'ok';
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { persistSession: false } },
    );
    const { error } = await supabase.from('church').select('id').limit(1);
    if (error) db = 'error';
  } catch (_e) {
    db = 'error';
  }

  return new Response(
    JSON.stringify({
      ok: db === 'ok',
      db,
      ms: Date.now() - started,
      ts: new Date().toISOString(),
    }),
    {
      headers: { 'content-type': 'application/json' },
      status: db === 'ok' ? 200 : 503,
    },
  );
});
