/// Canonical enums shared across the app. Each mirrors a type or check-constrained column
/// in the Supabase schema (see supabase/migrations). `wireValue` is the exact string stored
/// in Postgres — never rename without a matching migration.

/// RBAC roles (ADR 0003). Stored in `user_roles.role` and injected into the JWT.
enum AppRole {
  superAdmin('super_admin'),
  pastorAdmin('pastor_admin'),
  finance('finance'),
  contentEditor('content_editor'),
  member('member'),
  anonymous('anonymous');

  const AppRole(this.wireValue);
  final String wireValue;

  static AppRole fromWire(String v) => AppRole.values
      .firstWhere((r) => r.wireValue == v, orElse: () => AppRole.member);
}

/// RBAC permissions (ADR 0003). Stored in `role_permissions.permission`; checked by the
/// `authorize(permission)` RLS helper. Extended per slice.
enum AppPermission {
  hymnsManage('hymns.manage'),
  eventsManage('events.manage'),
  mediaManage('media.manage'),
  scheduleManage('schedule.manage'),
  focusManage('focus.manage'),
  announcementsSend('announcements.send'),
  givingRead('giving.read'),
  givingReadIdentity('giving.read_identity'),
  rolesManage('roles.manage');

  const AppPermission(this.wireValue);
  final String wireValue;
}

/// Structural type of a hymn section (v1 hymnal). Mirrors `hymn_sections.section_type`.
enum HymnSectionType {
  verse('verse'),
  chorus('chorus'),
  refrain('refrain'),
  bridge('bridge'),
  preChorus('pre_chorus'),
  ending('ending');

  const HymnSectionType(this.wireValue);
  final String wireValue;

  static HymnSectionType fromWire(String v) => HymnSectionType.values
      .firstWhere((s) => s.wireValue == v, orElse: () => HymnSectionType.verse);
}

/// Kind of asset attached to a hymn (v1: sheet-music PDF). Mirrors `hymn_assets.kind`.
enum HymnAssetKind {
  sheetMusicPdf('sheet_music_pdf'),
  sheetMusicImage('sheet_music_image'),
  audio('audio'),
  midi('midi'),
  chordChart('chord_chart');

  const HymnAssetKind(this.wireValue);
  final String wireValue;

  static HymnAssetKind fromWire(String v) => HymnAssetKind.values.firstWhere(
        (k) => k.wireValue == v,
        orElse: () => HymnAssetKind.sheetMusicPdf,
      );
}

/// Which hymn presentation the user sees (client-only; persisted preference).
enum HymnViewMode { ordinary, chorister }

/// Kind of reading (ADR 0008). Mirrors the `reading_kind` Postgres enum.
enum ReadingKind {
  responsiveReading('responsive_reading'),
  callToWorship('call_to_worship'),
  benediction('benediction'),
  creed('creed'),
  covenant('covenant');

  const ReadingKind(this.wireValue);
  final String wireValue;

  static ReadingKind fromWire(String v) => ReadingKind.values.firstWhere(
        (k) => k.wireValue == v,
        orElse: () => ReadingKind.responsiveReading,
      );
}

/// Who reads a part of a reading aloud (ADR 0008). Mirrors the `reading_speaker` Postgres
/// enum; a null speaker means it doesn't matter.
enum ReadingSpeaker {
  leader('leader'),
  people('people'),
  all('all');

  const ReadingSpeaker(this.wireValue);
  final String wireValue;

  static ReadingSpeaker? fromWire(String? v) {
    for (final s in ReadingSpeaker.values) {
      if (s.wireValue == v) return s;
    }
    return null;
  }
}
