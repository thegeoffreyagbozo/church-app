-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ 0005: The church's tagline (ADR 0007): a line under its name on Home,      ║
-- ║ such as its motto. It is public like the rest of the row: church_read_all  ║
-- ║ and the table-wide select grant cover a new column; admins edit it.        ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- May hold a line break; null when the church has none.
alter table public.church add column tagline text;
