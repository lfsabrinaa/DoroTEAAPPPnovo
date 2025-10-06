import 'dart:math';
import '../models/humor_event.dart';

List<HumorEvent> generateSimulatedData() {
  final random = Random();
  final List<HumorEvent> data = [];
  final DateTime now = DateTime.now();

  final List<String> musicas = [
    'Música Relaxante',
    'Sons da Natureza',
    'Canção de Ninar',
    'Melodia Feliz'
  ];

  for (int i = 0; i < 20; i++) {
    final DateTime eventTime = now.subtract(Duration(days: i, hours: random.nextInt(24)));
    final int humorValue = random.nextInt(4) + 1; // De 1 a 4

    data.add(HumorEvent(
      dataHora: eventTime,
      humor: humorValue,
      musica: musicas[random.nextInt(musicas.length)],
      duracao: '${random.nextInt(5) + 1} min',
      mudancaHumor: _getHumorChange(humorValue),
    ));
  }

  // Ordenar por dataHora para que o gráfico seja linear
  data.sort((a, b) => a.dataHora.compareTo(b.dataHora));

  return data;
}

String _getHumorChange(int humor) {
  switch (humor) {
    case 1: return 'Mudança para triste';
    case 2: return 'Mudança para neutro';
    case 3: return 'Mudança para feliz';
    case 4: return 'Mudança para estressado';
    default: return 'Mudança neutra';
  }
}