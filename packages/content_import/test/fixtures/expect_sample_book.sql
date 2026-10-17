-- Checks a database after sample_book.txt was imported twice (see .github/workflows/ci.yml).
do $$
begin
  assert (select count(*) from public.hymns h join public.hymnals y on y.id = h.hymnal_id
          where y.name in ('Service Music', 'Hymns', 'Supplementary Hymns')) = 5,
    'importing twice must update the 5 hymns, not duplicate them';
  assert (select count(*) from public.hymn_sections s join public.hymns h on h.id = s.hymn_id
          where h.title = 'Rock of Ages' and s.deleted_at is null) = 2,
    'Rock of Ages has 2 verses';
  assert (select section_type from public.hymn_sections s join public.hymns h on h.id = s.hymn_id
          where h.title = 'Blessed Assurance' and s.position = 1) = 'chorus',
    'the chorus keeps its place after verse 1';
  assert (select c.name from public.hymns h join public.hymn_categories c on c.id = h.category_id
          where h.title = 'Let Us Break Bread Together') = 'Communion',
    'a TOPIC becomes the hymn''s category';
  assert (select c.theme || ' / ' || c.name from public.hymns h
          join public.hymn_categories c on c.id = h.category_id
          join public.hymnals y on y.id = c.hymnal_id
          where h.title = 'Rock of Ages' and y.name = 'Hymns') = 'Hymns of Worship / General',
    'a GROUP becomes a category of its section';
  assert not (select published from public.hymns where title = 'A Protected Hymn'),
    'a protected hymn stays unpublished';
  assert not (select published from public.readings where title = 'Unfinished Reading'),
    'a draft stays unpublished';
  assert (select count(*) from public.reading_parts p join public.readings r on r.id = p.reading_id
          where r.number = 12 and p.number is not null) = 2,
    'the benedictions keep their numbered items';
  assert (select p.scripture_ref from public.reading_parts p join public.readings r on r.id = p.reading_id
          where r.number = 11 and p.position = 1) = 'Psalm 23:1-2',
    'a Ref attaches to the line before it';
  assert (select bool_and(speaker = 'all') from public.reading_parts p
          join public.readings r on r.id = p.reading_id where r.title = 'The Church Covenant'),
    'a covenant is read by everyone';
end $$;

-- What the public API can see: published content only.
set role anon;
do $$
begin
  assert (select count(*) from public.hymns where title = 'A Protected Hymn') = 0,
    'anonymous users must not see an unpublished hymn';
  assert (select count(*) from public.hymns where title = 'Rock of Ages') = 1,
    'anonymous users see a published hymn';
  assert (select count(*) from public.readings where title = 'Unfinished Reading') = 0,
    'anonymous users must not see a draft reading';
end $$;
reset role;
