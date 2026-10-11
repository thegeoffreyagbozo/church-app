-- Sample/dev seed data. Applied by `supabase db reset` (local) and useful for CI.
-- Public-domain hymns only. Fixed UUIDs + ON CONFLICT make this re-runnable.

-- Name the seeded church (row created in migration 0001).
update public.church
set name = 'Grace Chapel (Demo)',
    email = 'hello@example.church',
    phone = '+233200000000',
    website = 'https://example.church',
    socials = '{"facebook":"https://facebook.com/example","youtube":"https://youtube.com/@example"}'::jsonb
where id = '00000000-0000-0000-0000-000000000001';

-- Default English hymnal (published so it is visible to anonymous users).
insert into public.hymnals (id, name, language, description, is_default, sort_order, published)
values ('10000000-0000-0000-0000-000000000001', 'Church Hymnal', 'en',
        'Default English hymnal', true, 0, true)
on conflict (id) do nothing;

-- Categories
insert into public.hymn_categories (id, hymnal_id, key, name, theme, sort_order) values
  ('11000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'praise',   'Praise & Adoration', 'praise',    0),
  ('11000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'grace',    'Grace & Salvation',  'salvation', 1),
  ('11000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'comfort',  'Comfort & Peace',    'comfort',   2)
on conflict (id) do nothing;

-- ── Hymn 1: Amazing Grace (verses only) ───────────────────────────────────────
insert into public.hymns
  (id, hymnal_id, category_id, number, title, first_line, author, composer, tune_name,
   meter, music_key, scripture_ref, language, is_public_domain, chorister_notes, published)
values
  ('12000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
   '11000000-0000-0000-0000-000000000002', 1, 'Amazing Grace', 'Amazing grace! how sweet the sound',
   'John Newton', 'Traditional (NEW BRITAIN)', 'NEW BRITAIN', 'C.M.', 'G', 'Ephesians 2:8',
   'en', true, 'Pickup note on "A-"; hold the fermata on "saved a wretch".', true)
on conflict (id) do nothing;

insert into public.hymn_sections (id, hymn_id, section_type, section_number, position, lyrics) values
  ('13000000-0000-0000-0000-000000000011', '12000000-0000-0000-0000-000000000001', 'verse', 1, 0,
   E'Amazing grace! how sweet the sound,\nThat saved a wretch like me!\nI once was lost, but now am found,\nWas blind, but now I see.'),
  ('13000000-0000-0000-0000-000000000012', '12000000-0000-0000-0000-000000000001', 'verse', 2, 1,
   E'''Twas grace that taught my heart to fear,\nAnd grace my fears relieved;\nHow precious did that grace appear\nThe hour I first believed!'),
  ('13000000-0000-0000-0000-000000000013', '12000000-0000-0000-0000-000000000001', 'verse', 3, 2,
   E'Through many dangers, toils and snares,\nI have already come;\n''Tis grace hath brought me safe thus far,\nAnd grace will lead me home.')
on conflict (id) do nothing;

-- ── Hymn 2: It Is Well With My Soul (verses + refrain → exercises chorus view) ─
insert into public.hymns
  (id, hymnal_id, category_id, number, title, first_line, author, composer, tune_name,
   meter, music_key, scripture_ref, language, is_public_domain, chorister_notes, published)
values
  ('12000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001',
   '11000000-0000-0000-0000-000000000003', 2, 'It Is Well With My Soul',
   'When peace like a river attendeth my way', 'Horatio G. Spafford', 'Philip P. Bliss', 'VILLE DU HAVRE',
   '11.8.11.9 with refrain', 'C', '2 Kings 4:26', 'en', true,
   'Refrain in four parts; sopranos lead the echo "It is well".', true)
on conflict (id) do nothing;

insert into public.hymn_sections (id, hymn_id, section_type, section_number, position, lyrics) values
  ('13000000-0000-0000-0000-000000000021', '12000000-0000-0000-0000-000000000002', 'verse', 1, 0,
   E'When peace like a river attendeth my way,\nWhen sorrows like sea billows roll;\nWhatever my lot, Thou hast taught me to say,\nIt is well, it is well with my soul.'),
  ('13000000-0000-0000-0000-000000000022', '12000000-0000-0000-0000-000000000002', 'chorus', null, 1,
   E'It is well (it is well),\nWith my soul (with my soul),\nIt is well, it is well with my soul.'),
  ('13000000-0000-0000-0000-000000000023', '12000000-0000-0000-0000-000000000002', 'verse', 2, 2,
   E'Though Satan should buffet, though trials should come,\nLet this blest assurance control,\nThat Christ hath regarded my helpless estate,\nAnd hath shed His own blood for my soul.')
on conflict (id) do nothing;

-- ── Hymn 3: Holy, Holy, Holy (verse only sample) ──────────────────────────────
insert into public.hymns
  (id, hymnal_id, category_id, number, title, first_line, author, composer, tune_name,
   meter, music_key, scripture_ref, language, is_public_domain, chorister_notes, published)
values
  ('12000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001',
   '11000000-0000-0000-0000-000000000001', 3, 'Holy, Holy, Holy',
   'Holy, holy, holy! Lord God Almighty', 'Reginald Heber', 'John B. Dykes', 'NICAEA',
   '11.12.12.10', 'D', 'Revelation 4:8', 'en', true, 'Unison verse 1; harmony from verse 2.', true)
on conflict (id) do nothing;

insert into public.hymn_sections (id, hymn_id, section_type, section_number, position, lyrics) values
  ('13000000-0000-0000-0000-000000000031', '12000000-0000-0000-0000-000000000003', 'verse', 1, 0,
   E'Holy, holy, holy! Lord God Almighty!\nEarly in the morning our song shall rise to Thee;\nHoly, holy, holy! merciful and mighty!\nGod in three Persons, blessed Trinity!')
on conflict (id) do nothing;

-- Note: hymn_assets (sheet-music PDFs) are uploaded by staff via the admin panel, so none
-- are seeded here. The chorister view shows notation metadata (key/tune/meter) + any PDF.
