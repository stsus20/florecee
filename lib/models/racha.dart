import 'cuidado.dart';

enum EtapaRacha { semilla, brote, tallo, flor }

class CrecimientoRacha {
  final int dias;
  const CrecimientoRacha(this.dias);
  int get diasVisuales => dias.clamp(0, 30);
  EtapaRacha get etapa => switch (diasVisuales) {
    0 => EtapaRacha.semilla,
    <= 10 => EtapaRacha.brote,
    <= 20 => EtapaRacha.tallo,
    _ => EtapaRacha.flor,
  };
  String get nombre => switch (etapa) {
    EtapaRacha.semilla => 'Todo empieza aquí',
    EtapaRacha.brote => 'Un pequeño brote',
    EtapaRacha.tallo => 'Echando raíces',
    EtapaRacha.flor => 'Tu constancia florece',
  };
  double get progreso => diasVisuales / 30;
  String get siguiente => dias <= 0
      ? 'Tu primer cuidado hará brotar una nueva historia.'
      : dias <= 10
      ? 'El día 11 tu brote se convertirá en tallo.'
      : dias <= 20
      ? 'El día 21 aparecerá tu primera margarita.'
      : dias < 30
      ? 'Tu margarita seguirá abriéndose hasta el día 30.'
      : 'Tu margarita está completa. La racha puede seguir creciendo.';
}

int calcularRacha(Iterable<DateTime> registros, DateTime ahora) {
  final hoy = dia(ahora);
  final dias = registros.map(dia).where((d) => !d.isAfter(hoy)).toSet();
  var actual = hoy;
  if (!dias.contains(actual)) {
    actual = DateTime(actual.year, actual.month, actual.day - 1);
  }
  var total = 0;
  while (dias.contains(actual)) {
    total++;
    actual = DateTime(actual.year, actual.month, actual.day - 1);
  }
  return total;
}
