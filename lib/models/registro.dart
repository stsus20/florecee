class Registro {
  final int? id;
  final int plantaId, hojas, porcentaje;
  final DateTime fecha;
  final String nombre, especie, tipoCuidado, mito, foto, pdf;
  final bool amarillas;
  final double altura, anchura;
  const Registro({
    this.id,
    required this.plantaId,
    required this.fecha,
    required this.nombre,
    required this.especie,
    required this.tipoCuidado,
    required this.mito,
    required this.hojas,
    required this.amarillas,
    required this.porcentaje,
    required this.altura,
    required this.anchura,
    required this.foto,
    required this.pdf,
  });
  void validate() {
    if (hojas < 0 ||
        (!amarillas && porcentaje != 0) ||
        (amarillas && (porcentaje < 1 || porcentaje > 100 || hojas == 0)) ||
        !altura.isFinite ||
        !anchura.isFinite ||
        altura <= 0 ||
        anchura <= 0 ||
        foto.isEmpty ||
        pdf.isEmpty ||
        nombre.trim().isEmpty ||
        !['normal', 'mito'].contains(tipoCuidado) ||
        (tipoCuidado == 'mito' && mito.trim().isEmpty)) {
      throw ArgumentError('Completa correctamente el registro');
    }
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'plantaId': plantaId,
    'fecha': fecha.toIso8601String(),
    'nombre': nombre,
    'especie': especie,
    'tipoCuidado': tipoCuidado,
    'mito': mito,
    'hojas': hojas,
    'amarillas': amarillas ? 1 : 0,
    'porcentaje': porcentaje,
    'altura': altura,
    'anchura': anchura,
    'foto': foto,
    'pdf': pdf,
  };
  factory Registro.fromMap(Map<String, Object?> m) => Registro(
    id: m['id'] as int?,
    plantaId: m['plantaId'] as int,
    fecha: DateTime.parse(m['fecha'] as String),
    nombre: m['nombre'] as String,
    especie: m['especie'] as String,
    tipoCuidado: m['tipoCuidado'] as String,
    mito: m['mito'] as String,
    hojas: m['hojas'] as int,
    amarillas: m['amarillas'] == 1,
    porcentaje: m['porcentaje'] as int,
    altura: (m['altura'] as num).toDouble(),
    anchura: (m['anchura'] as num).toDouble(),
    foto: m['foto'] as String,
    pdf: m['pdf'] as String,
  );
  List<List<String>> get tabla => [
    ['Tipo de cuidado', tipoCuidado == 'mito' ? 'Mito' : 'Normal'],
    if (tipoCuidado == 'mito') ['Mito registrado', mito],
    ['¿Cuántas hojas tiene?', '$hojas'],
    ['¿Están amarillas?', amarillas ? 'Sí' : 'No'],
    [
      '¿Qué tanto?',
      amarillas ? '$porcentaje % de las hojas' : '0 % - sin hojas amarillas',
    ],
    ['Altura del tallo', '${medida(altura)} cm'],
    ['Anchura del tallo', '${medida(anchura)} cm'],
  ];
}

String medida(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
double? parseMedida(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));
Map<int, Registro> ultimosRegistros(Iterable<Registro> registros) {
  final result = <int, Registro>{};
  for (final r in registros) {
    final old = result[r.plantaId];
    if (old == null ||
        r.fecha.isAfter(old.fecha) ||
        (r.fecha == old.fecha && (r.id ?? 0) > (old.id ?? 0))) {
      result[r.plantaId] = r;
    }
  }
  return result;
}
