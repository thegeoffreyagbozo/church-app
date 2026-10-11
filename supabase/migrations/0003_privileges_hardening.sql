-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 0003: Table privileges and function hardening                              ║
-- ║ Cloud projects are created with "Automatically expose new tables" off, so  ║
-- ║ new tables get no select/insert/update/delete grants by default there.     ║
-- ║ Local stacks still auto-grant them, which hid the gap from CI.             ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ── Service role: full access to app tables, now and for future ones ─────────
-- Edge Functions use the service-role key (server-side only, ADR 0006). Without
-- these grants it could not even read public.church, so the health check failed.
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
alter default privileges for role postgres in schema public
  grant all on tables to service_role;
alter default privileges for role postgres in schema public
  grant all on sequences to service_role;

-- ── Clients: explicit grants only, in local stacks too ───────────────────────
-- Matches the cloud defaults, so a migration that forgets an explicit grant
-- fails in CI instead of in the cloud.
alter default privileges for role postgres in schema public
  revoke select, insert, update, delete on tables from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke all on sequences from anon, authenticated;

-- ── Functions: pin search_path (Supabase advisor 0011) ───────────────────────
-- Their bodies already use schema-qualified names, so an empty search_path is safe.
alter function public.set_updated_at() set search_path = '';
alter function public.custom_access_token_hook(jsonb) set search_path = '';
alter function public.is_admin() set search_path = '';
alter function public.is_staff() set search_path = '';

-- ── Trigger functions are not API endpoints (Supabase advisors 0028, 0029) ───
-- Triggers keep firing: Postgres checks EXECUTE only when a trigger is created.
-- public.authorize() stays executable on purpose: every RLS policy calls it as
-- the querying role, and it only reports the caller's own permissions.
revoke execute on function public.set_updated_at() from public, anon, authenticated;
revoke execute on function public.record_tombstone() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
