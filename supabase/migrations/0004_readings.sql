-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 0004: Readings (ADR 0008): responsive readings, calls to worship,          ║
-- ║ benedictions, creeds and church covenants. Mirrors the hymnal tables:      ║
-- ║ public read when published, writes need authorize('hymns.manage'), and     ║
-- ║ the sync spine (updated_at trigger + tombstone on soft delete).            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

create type public.reading_kind as enum
  ('responsive_reading', 'call_to_worship', 'benediction', 'creed', 'covenant');

-- Who reads a part aloud; null when it doesn't matter.
create type public.reading_speaker as enum ('leader', 'people', 'all');

-- ── Readings ──────────────────────────────────────────────────────────────────
create table public.readings (
  id               uuid primary key default gen_random_uuid(),
  kind             public.reading_kind not null default 'responsive_reading',
  number           int,                             -- null for unnumbered ones (creeds, covenants)
  title            text not null,
  scripture_ref    text,
  language         text not null default 'en',
  copyright        text,
  is_public_domain boolean not null default true,
  sort_order       int not null default 0,
  published        boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (language, number)                         -- books number readings apart from hymns
);
create index readings_updated_at_idx on public.readings (updated_at);

-- ── Parts (ordered; a collection's items carry their own number + reference) ──
create table public.reading_parts (
  id            uuid primary key default gen_random_uuid(),
  reading_id    uuid not null references public.readings(id) on delete cascade,
  position      int not null default 0,             -- render order within the reading
  number        int,                                -- item number inside a collection
  speaker       public.reading_speaker,
  body          text not null default '',           -- line breaks, "- " bullets and **bold** allowed
  scripture_ref text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index reading_parts_reading_idx    on public.reading_parts (reading_id, position);
create index reading_parts_updated_at_idx on public.reading_parts (updated_at);

-- ── Sync triggers (updated_at + tombstone) ────────────────────────────────────
do $$
declare t text;
begin
  foreach t in array array['readings','reading_parts']
  loop
    execute format(
      'create trigger %I_set_updated_at before update on public.%I
         for each row execute function public.set_updated_at();', t, t);
    execute format(
      'create trigger %I_tombstone after update on public.%I
         for each row execute function public.record_tombstone();', t, t);
  end loop;
end $$;

-- ── RLS: public read of published, non-deleted rows; writes need hymns.manage ──
-- Client grants are explicit: new tables get none by default (migration 0003).
do $$
declare t text;
begin
  foreach t in array array['readings','reading_parts']
  loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('grant select on public.%I to anon, authenticated;', t);
    execute format('grant insert, update, delete on public.%I to authenticated;', t);
    execute format(
      'create policy %I_write_manage on public.%I for all to authenticated
         using (public.authorize(''hymns.manage'')) with check (public.authorize(''hymns.manage''));',
      t, t);
  end loop;
end $$;

create policy readings_read on public.readings
  for select to anon, authenticated using (published and deleted_at is null);
-- Parts follow their reading's published state.
create policy reading_parts_read on public.reading_parts
  for select to anon, authenticated using (
    deleted_at is null and exists (
      select 1 from public.readings r
      where r.id = reading_id and r.published and r.deleted_at is null));
