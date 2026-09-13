enum TipoCuidado { riego, abono, revision, humeda, trasplante }

extension TipoTexto on TipoCuidado {
  String get label => switch (this) {
    TipoCuidado.riego => 'La regué',
    TipoCuidado.abono => 'La fertilicé',
    TipoCuidado.revision => 'Revisada',
    TipoCuidado.humeda => 'Sigue húmeda',
    TipoCuidado.trasplante => 'Trasplantada',
  };
  String get tarea => switch (this) {
    TipoCuidado.riego => 'Revisar humedad para riego',
    TipoCuidado.abono => 'Revisar fertilización',
    TipoCuidado.trasplante => 'Revisar trasplante',
    _ => 'Revisar humedad',
  };
}

DateTime dia(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime siguienteRevision(DateTime base, int dias) {
  if (dias < 1) {
    throw ArgumentError('El intervalo debe ser positivo');
  }
  return DateTime(base.year, base.month, base.day + dias, 9);
}

bool mismoDia(DateTime a, DateTime b) => dia(a) == dia(b);

class Cuidado {
  final int id, plantaId;
  final TipoCuidado tipo;
  final DateTime fecha;
  final String notas;
  Cuidado.fromMap(Map<String, Object?> m)
    : id = m['id'] as int,
      plantaId = m['plantaId'] as int,
      tipo = TipoCuidado.values.byName(m['tipo'] as String),
      fecha = DateTime.parse(m['fecha'] as String),
      notas = m['notas'] as String;
}

class Recordatorio {
  final int id, plantaId;
  final TipoCuidado tipo;
  final DateTime fecha;
  Recordatorio.fromMap(Map<String, Object?> m)
    : id = m['id'] as int,
      plantaId = m['plantaId'] as int,
      tipo = TipoCuidado.values.byName(m['tipo'] as String),
      fecha = DateTime.parse(m['fecha'] as String);
}
