-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 0002 — Hymnal (v1.0.0): hymnals, categories, hymns, sections, assets        ║
-- ║ Public-read when published; writes gated by authorize('hymns.manage').      ║
-- ║ Every table carries the sync spine: updated_at trigger + soft-delete tomb.  ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Reusable: attach the standard sync triggers (updated_at bump + tombstone on delete).
-- (Written inline per table below for clarity.)

-- ── Hymnals (books; supports English + Ghanaian-language books) ───────────────
create table public.hymnals (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  language    text not null default 'en',       -- 'en','tw','ee','gaa','fat'
  description text,
  is_default  boolean not null default false,
  sort_order  int not null default 0,
  published   boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

-- ── Categories / themes (church-editable lookup) ──────────────────────────────
create table public.hymn_categories (
  id         uuid primary key default gen_random_uuid(),
  hymnal_id  uuid references public.hymnals(id) on delete set null,  -- null = global
  key        text not null,
  name       text not null,
  theme      text,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

-- ── Hymns ─────────────────────────────────────────────────────────────────────
create table public.hymns (
  id              uuid primary key default gen_random_uuid(),
  hymnal_id       uuid not null references public.hymnals(id) on delete cascade,
  category_id     uuid references public.hymn_categories(id) on delete set null,
  number          int,
  title           text not null,
  first_line      text,
  author          text,
  composer        text,
  tune_name       text,
  meter           text,
  music_key       text,
  scripture_ref   text,
  language        text not null default 'en',
  copyright       text,
  is_public_domain boolean not null default true,
  chorister_notes text,                           -- chorister-only annotations (e.g. solfa)
  sort_order      int not null default 0,
  published       boolean not null default false,
  search_vector   tsvector generated always as (
      setweight(to_tsvector('simple', coalesce(title, '')),             'A') ||
      setweight(to_tsvector('simple', coalesce(number::text, '')),      'A') ||
      setweight(to_tsvector('simple', coalesce(first_line, '')),        'B') ||
      setweight(to_tsvector('simple', coalesce(author, '')),            'C') ||
      setweight(to_tsvector('simple', coalesce(composer, '')),          'D')
  ) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (hymnal_id, number)
);
create index hymns_search_idx    on public.hymns using gin (search_vector);
create index hymns_title_trgm_idx on public.hymns using gin (title extensions.gin_trgm_ops);
create index hymns_updated_at_idx on public.hymns (updated_at);
create index hymns_hymnal_idx     on public.hymns (hymnal_id);

-- ── Sections (verses / chorus, ordered) ───────────────────────────────────────
create table public.hymn_sections (
  id              uuid primary key default gen_random_uuid(),
  hymn_id         uuid not null references public.hymns(id) on delete cascade,
  section_type    text not null default 'verse'
                  check (section_type in ('verse','chorus','refrain','bridge','pre_chorus','ending')),
  section_number  int,
  position        int not null default 0,         -- render order of the whole hymn
  lyrics          text not null default '',
  chorister_lyrics text,                           -- optional annotated variant
  notes           text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index hymn_sections_hymn_idx on public.hymn_sections (hymn_id, position);

-- ── Assets (sheet-music PDF = chorister view; also future audio/midi) ──────────
create table public.hymn_assets (
  id             uuid primary key default gen_random_uuid(),
  hymn_id        uuid not null references public.hymns(id) on delete cascade,
  kind           text not null default 'sheet_music_pdf'
                 check (kind in ('sheet_music_pdf','sheet_music_image','audio','midi','chord_chart')),
  storage_bucket text not null default 'sheet-music',
  storage_path   text not null,                    -- object path within the (public) bucket
  -- A VIEW hint only (sheet music surfaces in the chorister view); NOT an access gate.
  -- Per decision: sheet music is public to everyone. The bucket is public.
  chorister_only boolean not null default false,
  page           int,
  mime           text,
  size_bytes     bigint,
  sort_order     int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index hymn_assets_hymn_idx on public.hymn_assets (hymn_id, sort_order);

-- ── Sync triggers (updated_at + tombstone) on every hymnal table ──────────────
do $$
declare t text;
begin
  foreach t in array array['hymnals','hymn_categories','hymns','hymn_sections','hymn_assets']
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
do $$
declare t text;
begin
  foreach t in array array['hymnals','hymn_categories','hymns','hymn_sections','hymn_assets']
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

-- Read policies: hymnals/hymns/categories gate on their own `published`+`deleted_at`;
-- sections/assets gate on their parent hymn's published state.
create policy hymnals_read on public.hymnals
  for select to anon, authenticated using (published and deleted_at is null);
create policy hymn_categories_read on public.hymn_categories
  for select to anon, authenticated using (deleted_at is null);
create policy hymns_read on public.hymns
  for select to anon, authenticated using (published and deleted_at is null);
create policy hymn_sections_read on public.hymn_sections
  for select to anon, authenticated using (
    deleted_at is null and exists (
      select 1 from public.hymns h
      where h.id = hymn_id and h.published and h.deleted_at is null));
create policy hymn_assets_read on public.hymn_assets
  for select to anon, authenticated using (
    deleted_at is null and exists (
      select 1 from public.hymns h
      where h.id = hymn_id and h.published and h.deleted_at is null));

-- ── Storage: public bucket for sheet-music PDFs (visible to everyone) ──────────
insert into storage.buckets (id, name, public)
values ('sheet-music', 'sheet-music', true)
on conflict (id) do nothing;

-- Staff may upload/replace; anyone may read (bucket is public).
create policy "sheet-music staff write" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'sheet-music' and public.authorize('hymns.manage'));
create policy "sheet-music staff update" on storage.objects
  for update to authenticated
  using (bucket_id = 'sheet-music' and public.authorize('hymns.manage'));
create policy "sheet-music staff delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'sheet-music' and public.authorize('hymns.manage'));
