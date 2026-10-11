-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 0001 — Auth core: extensions, RBAC, church singleton, profiles, sync spine ║
-- ║ Canonical decisions: ADR 0002 (sync/tombstones), 0003 (auth/RBAC),         ║
-- ║ 0005 (single church). Deny-by-default RLS on every table.                  ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ── Extensions ────────────────────────────────────────────────────────────────
create extension if not exists pgcrypto with schema extensions;   -- gen_random_uuid()
create extension if not exists pg_trgm  with schema extensions;   -- fuzzy search
create extension if not exists citext   with schema extensions;   -- case-insensitive email
-- Extension objects live in the `extensions` schema: always schema-qualify them
-- (e.g. extensions.citext). `supabase db push` to a cloud project runs without
-- `extensions` on the search_path, unlike the local stack, so bare names fail there.

-- ── Shared helpers ──────────────────────────────────────────────────────────--
-- Bumps updated_at on every UPDATE (so a soft-delete also advances the sync cursor).
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ── Sync spine: tombstones (ADR 0002) ──────────────────────────────────────────
-- Soft-deleting a row writes a payload-free tombstone that offline clients sweep to
-- purge locally. Publicly readable (no payload => no RLS leak).
create table public.tombstones (
  id         bigint generated always as identity primary key,
  table_name text        not null,
  row_id     uuid        not null,
  deleted_at timestamptz not null default now()
);
create index tombstones_deleted_at_idx on public.tombstones (deleted_at);

-- Attached per-table (AFTER UPDATE) in each feature migration. Fires only on the
-- null -> not-null transition of deleted_at.
create or replace function public.record_tombstone()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.deleted_at is not null and old.deleted_at is null then
    insert into public.tombstones (table_name, row_id) values (tg_table_name, new.id);
  end if;
  return new;
end;
$$;

alter table public.tombstones enable row level security;
create policy tombstones_read_all on public.tombstones
  for select to anon, authenticated using (true);
-- No write policy: only the SECURITY DEFINER trigger inserts rows.
grant select on public.tombstones to anon, authenticated;

-- ── RBAC: roles & permissions (ADR 0003) ────────────────────────────────────--
create type public.app_role as enum
  ('super_admin', 'pastor_admin', 'finance', 'content_editor', 'member', 'anonymous');

create type public.app_permission as enum
  ('hymns.manage', 'events.manage', 'media.manage', 'schedule.manage', 'focus.manage',
   'announcements.send', 'giving.read', 'giving.read_identity', 'roles.manage');

create table public.user_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role    public.app_role not null,
  primary key (user_id, role)
);

create table public.role_permissions (
  role       public.app_role       not null,
  permission public.app_permission not null,
  primary key (role, permission)
);

-- Seed the permission matrix (static).
insert into public.role_permissions (role, permission) values
  -- super_admin: everything
  ('super_admin','hymns.manage'), ('super_admin','events.manage'), ('super_admin','media.manage'),
  ('super_admin','schedule.manage'), ('super_admin','focus.manage'), ('super_admin','announcements.send'),
  ('super_admin','giving.read'), ('super_admin','giving.read_identity'), ('super_admin','roles.manage'),
  -- pastor_admin: all content + schedule/focus + giving totals (not identity, not roles)
  ('pastor_admin','hymns.manage'), ('pastor_admin','events.manage'), ('pastor_admin','media.manage'),
  ('pastor_admin','schedule.manage'), ('pastor_admin','focus.manage'), ('pastor_admin','announcements.send'),
  ('pastor_admin','giving.read'),
  -- finance: money only
  ('finance','giving.read'), ('finance','giving.read_identity'),
  -- content_editor: content + announcements
  ('content_editor','hymns.manage'), ('content_editor','events.manage'),
  ('content_editor','media.manage'), ('content_editor','announcements.send')
on conflict do nothing;

-- ── JWT claim hook: inject user_roles (ADR 0003) ────────────────────────────--
-- Supabase Auth calls this on every token issue/refresh; RLS then reads the claim.
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb language plpgsql stable as $$
declare
  claims jsonb;
  roles  text[];
begin
  select coalesce(array_agg(role::text), array[]::text[])
    into roles
  from public.user_roles
  where user_id = (event->>'user_id')::uuid;

  claims := coalesce(event->'claims', '{}'::jsonb);
  claims := jsonb_set(claims, '{user_roles}', to_jsonb(roles));
  event  := jsonb_set(event, '{claims}', claims);
  return event;
end;
$$;

-- Only the auth admin may run the hook / read the roles table it needs.
grant usage on schema public to supabase_auth_admin;
grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
revoke execute on function public.custom_access_token_hook(jsonb) from authenticated, anon, public;
grant select on public.user_roles to supabase_auth_admin;

-- ── Authorization helpers (SECURITY DEFINER, read JWT claim — no table recursion) ──
create or replace function public.authorize(requested public.app_permission)
returns boolean language plpgsql stable security definer set search_path = '' as $$
declare
  granted int;
begin
  select count(*) into granted
  from public.role_permissions rp
  where rp.permission = requested
    and rp.role::text = any (
      coalesce(
        (select array(select jsonb_array_elements_text(auth.jwt()->'user_roles'))),
        array[]::text[]
      )
    );
  return granted > 0;
end;
$$;

create or replace function public.is_admin()
returns boolean language sql stable as $$
  select public.authorize('roles.manage');
$$;

-- "staff" = holds any content/management permission (used by storage write policies).
create or replace function public.is_staff()
returns boolean language sql stable as $$
  select public.authorize('hymns.manage') or public.authorize('events.manage')
      or public.authorize('media.manage') or public.authorize('schedule.manage')
      or public.authorize('focus.manage') or public.authorize('announcements.send')
      or public.authorize('giving.read')  or public.authorize('roles.manage');
$$;

-- ── Church profile singleton (ADR 0005) ─────────────────────────────────────--
create table public.church (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  logo_path  text,
  banner_path text,
  about      text,
  email      extensions.citext,
  phone      text,
  address    text,
  website    text,
  socials    jsonb not null default '{}'::jsonb,   -- {facebook, instagram, youtube, whatsapp, x, tiktok}
  currency   text  not null default 'GHS',
  timezone   text  not null default 'Africa/Accra',
  settings   jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- Guarantee exactly one church row exists (seeded here so cloud `db push` has it too).
insert into public.church (id, name)
values ('00000000-0000-0000-0000-000000000001', 'Your Church')
on conflict (id) do nothing;

create trigger church_set_updated_at before update on public.church
  for each row execute function public.set_updated_at();

alter table public.church enable row level security;
create policy church_read_all on public.church
  for select to anon, authenticated using (deleted_at is null);
create policy church_write_admin on public.church
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
grant select on public.church to anon, authenticated;
grant insert, update, delete on public.church to authenticated;

-- ── Profiles ────────────────────────────────────────────────────────────────--
create table public.profiles (
  id                uuid primary key references auth.users(id) on delete cascade,
  full_name         text not null default '',
  phone             text,
  phone_verified_at timestamptz,
  email             extensions.citext,
  avatar_path       text,
  preferred_language text,
  is_choir_member   boolean not null default false,  -- seeds the default hymnal view
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz
);

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
create policy profiles_read_own on public.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy profiles_admin_read on public.profiles
  for select to authenticated using (public.is_admin());
grant select, update on public.profiles to authenticated;

-- New non-anonymous users get a profile + the default 'member' role.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if coalesce(new.is_anonymous, false) = false then
    insert into public.profiles (id, full_name, phone, email)
    values (new.id,
            coalesce(new.raw_user_meta_data->>'full_name', ''),
            new.phone,
            new.email)
    on conflict (id) do nothing;

    insert into public.user_roles (user_id, role)
    values (new.id, 'member')
    on conflict do nothing;
  end if;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── RLS for RBAC tables ─────────────────────────────────────────────────────--
alter table public.user_roles enable row level security;
create policy user_roles_read_own on public.user_roles
  for select to authenticated using (user_id = (select auth.uid()));
create policy user_roles_admin_all on public.user_roles
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
-- The access-token hook runs AS supabase_auth_admin and is still subject to RLS; without
-- this policy it would read zero roles at token-issue time (Supabase gotcha).
create policy user_roles_authadmin_read on public.user_roles
  as permissive for select to supabase_auth_admin using (true);
grant select, insert, update, delete on public.user_roles to authenticated;

alter table public.role_permissions enable row level security;
create policy role_permissions_read on public.role_permissions
  for select to anon, authenticated using (true);
create policy role_permissions_admin_write on public.role_permissions
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
grant select on public.role_permissions to anon, authenticated;
grant insert, update, delete on public.role_permissions to authenticated;
