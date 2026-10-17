import 'plan.dart';

/// Renders [plan] as one SQL script, run in a single transaction.
///
/// Every row is upserted by id (clearing `deleted_at`, so a row deleted earlier comes back),
/// then each cleanup soft-deletes the children a batch no longer has. Soft deletes keep the
/// sync contract: the tombstone trigger tells offline devices to drop them (ADR 0002).
String renderSql(ImportPlan plan) {
  final out = StringBuffer('begin;\n\n');
  for (final row in plan.rows) {
    final columns = row.values.keys.toList();
    final updates = [
      for (final c in columns)
        if (c != 'id') '$c = excluded.$c',
      'deleted_at = null',
    ];
    out
      ..writeln('insert into public.${row.table} (${columns.join(', ')})')
      ..writeln(
        'values (${columns.map((c) => _literal(row.values[c])).join(', ')})',
      )
      ..writeln('on conflict (id) do update set ${updates.join(', ')};')
      ..writeln();
  }
  for (final c in plan.cleanups) {
    out
      ..writeln('update public.${c.table} set deleted_at = now()')
      ..writeln('where ${c.parentColumn} = ${_literal(c.parentId)} '
          'and ${c.orderColumn} >= ${c.keep} and deleted_at is null;')
      ..writeln();
  }
  out.writeln('commit;');
  return out.toString();
}

String _literal(Object? value) => switch (value) {
      null => 'null',
      bool() || int() => '$value',
      String() => "'${value.replaceAll("'", "''")}'",
      _ => throw ArgumentError.value(value, 'value', 'unsupported SQL value'),
    };
