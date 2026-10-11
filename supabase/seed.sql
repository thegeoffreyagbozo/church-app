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

-- ── Readings (ADR 0008): one of each shape, all public domain ─────────────────
insert into public.readings (id, kind, number, title, scripture_ref, published) values
  ('14000000-0000-0000-0000-000000000001', 'responsive_reading', 1, 'The Lord Is My Shepherd', 'Psalm 23', true),
  ('14000000-0000-0000-0000-000000000002', 'benediction', 2, 'Benedictions', null, true),
  ('14000000-0000-0000-0000-000000000003', 'creed', null, 'The Apostles'' Creed', null, true),
  ('14000000-0000-0000-0000-000000000004', 'covenant', null, 'A Church Covenant', null, true)
on conflict (id) do nothing;

insert into public.reading_parts (id, reading_id, position, number, speaker, body, scripture_ref) values
  -- Responsive: leader and congregation alternate (Psalm 23, KJV)
  ('15000000-0000-0000-0000-000000000011', '14000000-0000-0000-0000-000000000001', 0, null, 'leader',
   'The Lord is my shepherd; I shall not want.', null),
  ('15000000-0000-0000-0000-000000000012', '14000000-0000-0000-0000-000000000001', 1, null, 'people',
   'He maketh me to lie down in green pastures: he leadeth me beside the still waters.', null),
  ('15000000-0000-0000-0000-000000000013', '14000000-0000-0000-0000-000000000001', 2, null, 'leader',
   'He restoreth my soul: he leadeth me in the paths of righteousness for his name''s sake.', null),
  ('15000000-0000-0000-0000-000000000014', '14000000-0000-0000-0000-000000000001', 3, null, 'all',
   'Surely goodness and mercy shall follow me all the days of my life: and I will dwell in the house of the Lord for ever.', null),
  -- Collection: numbered items, each with its own reference
  ('15000000-0000-0000-0000-000000000021', '14000000-0000-0000-0000-000000000002', 0, 1, 'leader',
   'The Lord bless thee, and keep thee: the Lord make his face shine upon thee, and be gracious unto thee: the Lord lift up his countenance upon thee, and give thee peace.', 'Numbers 6:24-26'),
  ('15000000-0000-0000-0000-000000000022', '14000000-0000-0000-0000-000000000002', 1, 2, 'leader',
   'The grace of the Lord Jesus Christ, and the love of God, and the communion of the Holy Ghost, be with you all. Amen.', '2 Corinthians 13:14'),
  -- Creed, said together
  ('15000000-0000-0000-0000-000000000031', '14000000-0000-0000-0000-000000000003', 0, null, 'all',
   'I believe in God the Father Almighty, Maker of heaven and earth:', null),
  ('15000000-0000-0000-0000-000000000032', '14000000-0000-0000-0000-000000000003', 1, null, 'all',
   'And in Jesus Christ his only Son our Lord, who was conceived by the Holy Ghost, born of the Virgin Mary, suffered under Pontius Pilate, was crucified, dead, and buried: he descended into hell; the third day he rose again from the dead; he ascended into heaven, and sitteth on the right hand of God the Father Almighty; from thence he shall come to judge the quick and the dead.', null),
  ('15000000-0000-0000-0000-000000000033', '14000000-0000-0000-0000-000000000003', 2, null, 'all',
   'I believe in the Holy Ghost; the holy Christian Church; the communion of saints; the forgiveness of sins; the resurrection of the body, and the life everlasting. Amen.', null),
  -- Covenant: a numbered part with "- " bullets and **bold** emphasis (after J. Newton Brown, 1853)
  ('15000000-0000-0000-0000-000000000041', '14000000-0000-0000-0000-000000000004', 0, null, 'all',
   'Having been led, as we believe, by the Spirit of God, to receive the Lord Jesus Christ as our Saviour, we do now most solemnly and joyfully enter into **covenant** with one another, as one body in Christ.', null),
  ('15000000-0000-0000-0000-000000000042', '14000000-0000-0000-0000-000000000004', 1, 1, 'all',
   E'**We engage, therefore, by the aid of the Holy Spirit:**\n- to **walk** together in Christian love;\n- to **strive** for the advancement of this church;\n- to **sustain** its worship, ordinances, discipline, and doctrines.', null)
on conflict (id) do nothing;
