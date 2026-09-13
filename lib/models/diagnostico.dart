const sintomas = [
  'Hojas amarillas',
  'Manchas',
  'Hojas caídas',
  'Tallo blando',
  'Plagas visibles',
  'No florece',
  'Puntas cafés',
  'Crecimiento lento',
  'Moho',
  'Raíces oscuras o con mal olor',
];

class PosibleCausa {
  final String nombre, consejo;
  const PosibleCausa(this.nombre, this.consejo);
  Map<String, String> toMap() => {'nombre': nombre, 'consejo': consejo};
}

List<PosibleCausa> diagnosticar(Set<String> s, Map<String, String> r) {
  final causas = <PosibleCausa>[];
  void add(String n, String c) => causas.add(PosibleCausa(n, c));
  if (r['humedad'] == 'Húmeda' &&
      (s.contains('Hojas amarillas') ||
          s.contains('Tallo blando') ||
          r['riego'] == 'Sí')) {
    add(
      'Exceso de riego',
      'Espera a que el sustrato pierda humedad. Comprueba el interior antes de volver a regar.',
    );
  }
  if (r['humedad'] == 'Seca' &&
      (s.contains('Hojas caídas') || s.contains('Puntas cafés'))) {
    add(
      'Falta de agua',
      'Comprueba el cepellón. Si está seco, riega poco a poco y deja escurrir el excedente.',
    );
  }
  if (r['luz'] == 'Sombra' &&
      (s.contains('No florece') ||
          s.contains('Crecimiento lento') ||
          s.contains('Hojas amarillas'))) {
    add(
      'Falta de luz',
      'Acerca gradualmente la planta a una zona más luminosa según su especie.',
    );
  }
  if (r['luz'] == 'Sol directo' &&
      (s.contains('Manchas') || s.contains('Puntas cafés'))) {
    add(
      'Exceso de sol',
      'Evita el sol fuerte del mediodía y adapta la exposición gradualmente.',
    );
  }
  if (r['drenaje'] == 'No') {
    add(
      'Drenaje deficiente',
      'Retira agua del plato y valora una maceta con orificios; no riegues si sigue húmeda.',
    );
  }
  if (s.contains('Raíces oscuras o con mal olor') ||
      (s.contains('Tallo blando') && r['humedad'] == 'Húmeda')) {
    add(
      'Posible pudrición de raíces',
      'Revisa las raíces con cuidado y consulta a una persona especialista si hay olor o tejido blando.',
    );
  }
  if (s.contains('Plagas visibles') || r['insectos'] == 'Sí') {
    add(
      'Posible plaga',
      'Separa la planta y revisa el envés. Identifica la plaga antes de aplicar productos.',
    );
  }
  if (s.contains('Moho') ||
      (s.contains('Manchas') && r['humedad'] == 'Húmeda')) {
    add(
      'Posible problema de hongos',
      'Mejora la ventilación y evita mojar el follaje. No apliques fungicidas sin identificar el problema.',
    );
  }
  if (s.contains('Crecimiento lento') || s.contains('No florece')) {
    add(
      'Fertilización inadecuada',
      'Revisa la temporada y la guía de la especie. No fertilices una planta estresada ni aumentes dosis sin indicación.',
    );
  }
  if (causas.isEmpty) {
    add(
      'Información insuficiente',
      'Observa la evolución y compara las condiciones con la ficha de la especie. Consulta si empeora.',
    );
  }
  return causas;
}
