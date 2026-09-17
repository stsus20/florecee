class Planta {
  final int? id;
  final String nombre, especie, ubicacion, luz, recipiente, tamano, notas;
  final String? foto;
  final String tipoCuidado, mito;
  final bool drenaje;
  final int intervalo;
  final DateTime ultimoRiego;
  const Planta({
    this.id,
    required this.nombre,
    required this.especie,
    this.foto,
    required this.ubicacion,
    required this.luz,
    required this.recipiente,
    required this.tamano,
    required this.drenaje,
    required this.ultimoRiego,
    required this.intervalo,
    this.notas = '',
    this.tipoCuidado = 'normal',
    this.mito = '',
  });
  Map<String, Object?> toMap() => {
    'id': id,
    'nombre': nombre,
    'especie': especie,
    'foto': foto,
    'ubicacion': ubicacion,
    'luz': luz,
    'recipiente': recipiente,
    'tamano': tamano,
    'drenaje': drenaje ? 1 : 0,
    'ultimoRiego': ultimoRiego.toIso8601String(),
    'intervalo': intervalo,
    'notas': notas,
    'tipoCuidado': tipoCuidado,
    'mito': tipoCuidado == 'mito' ? mito.trim() : '',
  };
  factory Planta.fromMap(Map<String, Object?> m) => Planta(
    id: m['id'] as int,
    nombre: m['nombre'] as String,
    especie: m['especie'] as String,
    foto: m['foto'] as String?,
    ubicacion: m['ubicacion'] as String,
    luz: m['luz'] as String,
    recipiente: m['recipiente'] as String,
    tamano: m['tamano'] as String,
    drenaje: m['drenaje'] == 1,
    ultimoRiego: DateTime.parse(m['ultimoRiego'] as String),
    intervalo: m['intervalo'] as int,
    notas: m['notas'] as String,
    tipoCuidado: m['tipoCuidado'] as String? ?? 'normal',
    mito: m['mito'] as String? ?? '',
  );
}
