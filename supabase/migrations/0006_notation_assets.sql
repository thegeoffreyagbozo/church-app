-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 0006: Drawn notation (ADR 0012): MusicXML files join the hymn assets.      ║
-- ║ One `musicxml` row per hymn, its file at `<hymn id>/notation.mxl` in the   ║
-- ║ public `sheet-music` bucket, read under the existing hymn_assets policies. ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

alter table public.hymn_assets drop constraint hymn_assets_kind_check;
alter table public.hymn_assets add constraint hymn_assets_kind_check
  check (kind in ('sheet_music_pdf','sheet_music_image','musicxml','audio','midi','chord_chart'));
