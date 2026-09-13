import 'package:flutter_test/flutter_test.dart';
import 'package:florece/models/cuidado.dart';
import 'package:florece/models/diagnostico.dart';

void main() {
  test('Next revision crosses leap day and year at 9 AM', () {
    expect(
      siguienteRevision(DateTime(2024, 2, 28, 22), 2),
      DateTime(2024, 3, 1, 9),
    );
    expect(
      siguienteRevision(DateTime(2026, 12, 31), 1),
      DateTime(2027, 1, 1, 9),
    );
    expect(() => siguienteRevision(DateTime.now(), 0), throwsArgumentError);
  });
  test(
    'Calendar grouping ignores time of day',
    () => expect(
      mismoDia(DateTime(2026, 9, 12, 1), DateTime(2026, 9, 12, 23)),
      isTrue,
    ),
  );
  test('Wet roots trigger cautious rot and drainage advice', () {
    final r = diagnosticar(
      {'Tallo blando', 'Raíces oscuras o con mal olor'},
      {'humedad': 'Húmeda', 'drenaje': 'No'},
    );
    expect(
      r.map((c) => c.nombre),
      containsAll([
        'Exceso de riego',
        'Drenaje deficiente',
        'Posible pudrición de raíces',
      ]),
    );
  });
  test('Dry drooping plant suggests water shortage, not overwatering', () {
    final names = diagnosticar(
      {'Hojas caídas'},
      {'humedad': 'Seca'},
    ).map((c) => c.nombre);
    expect(names, contains('Falta de agua'));
    expect(names, isNot(contains('Exceso de riego')));
  });
  test('Pests, sunlight, shade, fungi and nutrition rules', () {
    expect(
      diagnosticar({'Plagas visibles'}, {}).map((c) => c.nombre),
      contains('Posible plaga'),
    );
    expect(
      diagnosticar(
        {'Puntas cafés'},
        {'luz': 'Sol directo'},
      ).map((c) => c.nombre),
      contains('Exceso de sol'),
    );
    expect(
      diagnosticar({'No florece'}, {'luz': 'Sombra'}).map((c) => c.nombre),
      containsAll(['Falta de luz', 'Fertilización inadecuada']),
    );
    expect(
      diagnosticar({'Moho'}, {}).map((c) => c.nombre),
      contains('Posible problema de hongos'),
    );
    expect(diagnosticar({}, {}).single.nombre, 'Información insuficiente');
  });
}
