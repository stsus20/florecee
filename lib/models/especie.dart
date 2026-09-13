class Especie {
  final Map<String, dynamic> data;
  const Especie(this.data);
  String get id => data['id'] as String;
  String get nombre => data['nombre'] as String;
  String get cientifico => data['cientifico'] as String;
  int get intervalo => data['intervalo'] as int;
  String texto(String key) => data[key]?.toString() ?? '';
}
