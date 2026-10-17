import 'package:drift/drift.dart';

// Content tables mirror the published rows of a church's Supabase project, keeping only
// the columns the app shows. The build tool fills them; the app only reads them.

/// A numbering series of the hymn book (Hymns, Supplementary Hymns, Service Music).
@DataClassName('HymnalRow')
class Hymnals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A topic such as Communion, or a heading of a section's contents such as "His Birth"
/// under the part "Jesus Our Savior".
@DataClassName('HymnCategoryRow')
class HymnCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// The section whose contents this heading belongs to; null for a topic shared by
  /// the whole book.
  TextColumn get sectionId => text().nullable()();

  /// The part a contents heading sits under (`theme` in Supabase); null for a topic
  /// or a part without subheadings.
  TextColumn get part => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HymnRow')
class Hymns extends Table {
  TextColumn get id => text()();
  TextColumn get hymnalId => text().references(Hymnals, #id)();
  TextColumn get categoryId =>
      text().nullable().references(HymnCategories, #id)();
  IntColumn get number => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get firstLine => text().nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get composer => text().nullable()();
  TextColumn get tuneName => text().nullable()();
  TextColumn get meter => text().nullable()();
  TextColumn get musicKey => text().nullable()();
  TextColumn get scriptureRef => text().nullable()();
  TextColumn get choristerNotes => text().nullable()();
  BoolColumn get isPublicDomain =>
      boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A verse or chorus, in the order the book prints them.
@DataClassName('HymnSectionRow')
class HymnSections extends Table {
  TextColumn get id => text()();
  TextColumn get hymnId => text().references(Hymns, #id)();
  TextColumn get sectionType => text()();
  IntColumn get sectionNumber => integer().nullable()();
  IntColumn get position => integer()();
  TextColumn get lyrics => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One piece of a hymn's printed music, bundled as `music/<id>.png` beside the
/// database, with its size so the app lays it out before the image loads.
@DataClassName('HymnMusicRow')
class HymnMusic extends Table {
  TextColumn get id => text()();
  TextColumn get hymnId => text().references(Hymns, #id)();
  IntColumn get position => integer()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A responsive reading, collection, creed or covenant (ADR 0008).
@DataClassName('ReadingRow')
class Readings extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  IntColumn get number => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get scriptureRef => text().nullable()();
  BoolColumn get isPublicDomain =>
      boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ReadingPartRow')
class ReadingParts extends Table {
  TextColumn get id => text()();
  TextColumn get readingId => text().references(Readings, #id)();
  IntColumn get position => integer()();
  IntColumn get number => integer().nullable()();
  TextColumn get speaker => text().nullable()();
  TextColumn get body => text()();
  TextColumn get scriptureRef => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The church profile (one row).
@DataClassName('ChurchRow')
class Church extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get website => text().nullable()();

  /// A line under the church's name on Home, such as its motto. Stored on one line;
  /// Home wraps it to the screen.
  TextColumn get tagline => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// When and from where this copy of the hymn book was built (one row, id 1).
@DataClassName('BundleInfoRow')
class BundleInfo extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get builtAt => dateTime()();
  TextColumn get source => text()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// Phone-only tables: never synced, kept when the content is replaced.

/// Reading settings as text values (see the app's settings feature).
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('RecentRow')
class RecentlyOpened extends Table {
  TextColumn get itemType => text()();
  TextColumn get itemId => text()();
  DateTimeColumn get openedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {itemType, itemId};
}
