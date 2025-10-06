import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dorotea_app/models/humor_event.dart';
import 'package:dorotea_app/humor_data_generator.dart';
import 'package:dorotea_app/Telas_X/profile_screen.dart';
import 'package:dorotea_app/Telas_X/about_screen.dart';
import 'package:dorotea_app/Telas_X/home_screen.dart';

class ReportScreen extends StatefulWidget {
  final String userEmail;
  const ReportScreen({super.key, required this.userEmail});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late List<HumorEvent> _humorData;
  late List<HumorEvent> _filteredData;
  String _selectedTimeframe = 'Semana';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    _humorData = generateSimulatedData();
    _filterData(_selectedTimeframe);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(email: widget.userEmail)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userEmail: widget.userEmail),
          ),
        );
        break;
    }
  }

  void _filterData(String timeframe) {
    setState(() {
      _selectedTimeframe = timeframe;
      final now = DateTime.now();
      _filteredData = _humorData.where((event) {
        if (timeframe == 'Dia') {
          return now.difference(event.dataHora).inHours <= 24;
        } else if (timeframe == 'Semana') {
          return now.difference(event.dataHora).inDays <= 7;
        } else {
          return now.difference(event.dataHora).inDays <= 30;
        }
      }).toList();
      
      _filteredData.sort((a, b) => a.dataHora.compareTo(b.dataHora));
    });
  }

  IconData _getHumorIcon(int humorValue) {
    switch (humorValue) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_neutral;
      case 3:
        return Icons.sentiment_satisfied;
      case 4:
        return Icons.mood_bad;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _getMostFrequentMood() {
    if (_filteredData.isEmpty) return 'N/A';
    final moodCounts = <int, int>{};
    for (final event in _filteredData) {
      moodCounts[event.humor] = (moodCounts[event.humor] ?? 0) + 1;
    }
    final mostFrequent = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _getHumorLabel(mostFrequent);
  }

  String _getHumorLabel(int humor) {
    switch (humor) {
      case 1: return 'Triste';
      case 2: return 'Neutro';
      case 3: return 'Feliz';
      case 4: return 'Estressado';
      default: return 'N/A';
    }
  }

  Color _getHumorColor(int humor) {
    switch (humor) {
      case 1: return Colors.blue;
      case 2: return Colors.grey;
      case 3: return Colors.green;
      case 4: return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getDateLabel(DateTime date) {
    if (_selectedTimeframe == 'Semana') {
      return DateFormat('EEE', 'pt_BR').format(date); // Seg, Ter, Qua...
    } else {
      return DateFormat('dd/MM').format(date); // 25/10
    }
  }

  String _getMostEffectiveMusic() {
    if (_filteredData.isEmpty) return 'N/A';
    
    // Calcula a eficácia das músicas (humor 3 e 4 são positivos)
    final musicEffectiveness = <String, List<int>>{};
    
    for (final event in _filteredData) {
      if (!musicEffectiveness.containsKey(event.musica)) {
        musicEffectiveness[event.musica] = [];
      }
      musicEffectiveness[event.musica]!.add(event.humor);
    }
    
    String mostEffective = 'N/A';
    double bestScore = 0;
    
    musicEffectiveness.forEach((music, humors) {
      // Calcula média dos humores para esta música
      final average = humors.reduce((a, b) => a + b) / humors.length;
      if (average > bestScore) {
        bestScore = average;
        mostEffective = music;
      }
    });
    
    return mostEffective;
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        title: Text(
          'DoroTEA',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card com filtros de tempo
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Período de Análise',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['Dia', 'Semana', 'Mês'].map((timeframe) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            onPressed: () => _filterData(timeframe),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedTimeframe == timeframe
                                  ? primaryPurple
                                  : Colors.grey[200],
                              foregroundColor: _selectedTimeframe == timeframe ? Colors.white : Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(timeframe, style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // Card com gráfico simplificado
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Humor dos Últimos Dias',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Gráfico de barras horizontal
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _selectedTimeframe == 'Mês' ? _filteredData.length : (_filteredData.length > 7 ? 7 : _filteredData.length),
                      itemBuilder: (context, index) {
                        final event = _filteredData.reversed.toList()[index];
                        final humorPercent = (event.humor / 4.0);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              // Data
                              SizedBox(
                                width: 60,
                                child: Text(
                                  _getDateLabel(event.dataHora),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                              // Ícone do humor
                              Icon(
                                _getHumorIcon(event.humor),
                                color: primaryPurple,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              // Barra de progresso
                              Expanded(
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: humorPercent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _getHumorColor(event.humor),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Label do humor
                              SizedBox(
                                width: 60,
                                child: Text(
                                  _getHumorLabel(event.humor),
                                  style: const TextStyle(fontSize: 11),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Card com resumo estatístico
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo do Período',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_filteredData.isNotEmpty) ...[
                    _buildStatRow('Total de registros:', '${_filteredData.length}'),
                    _buildStatRow('Humor mais frequente:', _getMostFrequentMood()),
                    _buildStatRow('Música mais eficaz:', _getMostEffectiveMusic()),
                  ] else
                    const Text('Nenhum dado disponível para o período selecionado.'),
                ],
              ),
            ),

            // Lista de eventos recentes
            if (_filteredData.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Últimos Registros',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredData.length > 5 ? 5 : _filteredData.length,
                      itemBuilder: (context, index) {
                        final event = _filteredData.reversed.toList()[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(_getHumorIcon(event.humor), color: primaryPurple, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM HH:mm').format(event.dataHora),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(event.musica, style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: primaryPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'DoroTEA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}