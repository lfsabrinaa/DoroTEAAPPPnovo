import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuidedMusic extends StatefulWidget {
  final String email;
  const GuidedMusic({super.key, required this.email});

  @override
  State<GuidedMusic> createState() => _GuidedMusicState();
}

class _GuidedMusicState extends State<GuidedMusic> {
  // IP do ESP32 (Servidor na Porta 80)
  static const String _espIp = 'http://192.168.40.113'; 
  
  // IP do Servidor Flask (Dados na Porta 5000)
  static const String _flaskIp = 'http://192.168.18.186:5000'; 

  final List<Map<String, dynamic>> _defaultMusicList = [
 { 'id': 'dorotea',
      'title': 'DoroTEA',
      'artist': '3403',
      'audioUrl': 'assets/audios/DoroTEA.mp3',
      'isDeletable': false,
      'icon': Icons.pets,
      'color': Colors.purple,
    },
    {
      'id': 'brilha_estrelinha',
      'title': 'Brilha Estrelinha',
      'artist': 'Anônimo',
      'audioUrl': 'assets/audios/bbee.mp3',
      'isDeletable': false,
      'icon': Icons.star,
      'color': Colors.amber,
    },
    {
      'id': 'clair_de_lune',
      'title': 'Clair de Lune',
      'artist': 'Claude Debussy',
      'audioUrl': 'assets/audios/clairdelune.mp3',
      'isDeletable': false,
      'icon': Icons.nightlight,
      'color': Colors.indigo,
    },
    {
      'id': 'lullaby',
      'title': 'Lullaby',
      'artist': 'Johannes Brahms',
      'audioUrl': 'assets/audios/lullabyy.mp3',
      'isDeletable': false,
      'icon': Icons.bedtime,
      'color': Colors.green,
    },
    {
      'id': 'bmp',
      'title': '60 BPM',
      'artist': 'Anônimo',
      'audioUrl': 'assets/audios/bmp.mp3',
      'isDeletable': false,
      'icon': Icons.favorite,
      'color': Colors.red,
    },  
  ];

  late List<Map<String, dynamic>> _userMusicList;
  int? _playingEspId;

  @override
  void initState() {
    super.initState();
    _userMusicList = [];
    _loadUserMusic();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // FUNÇÃO 1: CARREGAR MÚSICAS (Requisição GET para o Flask)
  void _loadUserMusic() async {
    final String userEmail = widget.email;
    if (userEmail.isEmpty) {
      debugPrint('Usuário não logado.');
      return;
    }

    final url = Uri.parse('$_flaskIp/musics/$userEmail'); 
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // Usar ?? [] para garantir que não haverá erro se 'musics' for nulo
        final List<dynamic> fetchedMusics = data['musics'] ?? []; 
        
        final List<Map<String, dynamic>> userMusics =
            List<Map<String, dynamic>>.from(fetchedMusics.map((music) {
          return {
            'id': music['id'].toString(),
            'title': music['title'] ?? 'Sem Título',
            'artist': music['artist'] ?? 'Sem Artista',
            'audioUrl': music['audioUrl'] ?? '',
            'isDeletable': music['isDeletable'] ?? true,
            'icon': Icons.music_note,
            'color': Theme.of(context).primaryColor,
          };
        }));
        
        // CORREÇÃO: Usar mounted antes de setState
        if (mounted) {
          setState(() {
            _userMusicList = userMusics;
          });
        }
        debugPrint('Músicas do usuário carregadas com sucesso.');
      } else {
        debugPrint('Erro ao carregar músicas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro de conexão ao carregar músicas: $e');
    }
  }

  // FUNÇÃO 2: PLAY (Requisição POST para o ESP32)
  Future<void> _playMusicOnEsp(String musicId, int index) async {
    // 1. Atualiza o estado IMEDIATAMENTE (Assume sucesso até prova em contrário)
    setState(() {
      _playingEspId = index;
    });
    
    final url = Uri.parse('$_espIp/play');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': musicId}),
      );

      if (response.statusCode == 200) {
        // Sucesso: Mantém o estado e notifica
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Música iniciada no DoroTEA!')),
          );
        }
      } else {
        // Falha HTTP (ex: 404, 500)
        if (mounted) {
          // 2. Reverte o estado (Rollback)
          setState(() {
            _playingEspId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao iniciar música. Status: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      // Falha de Conexão (SocketException)
      if (mounted) {
        // 2. Reverte o estado (Rollback)
        setState(() {
          _playingEspId = null; 
        });
        debugPrint('Erro ao enviar comando para o ESP: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão com o DoroTEA.')),
        );
      }
    }
  }

  // FUNÇÃO 3: STOP (Requisição POST para o ESP32)
  Future<void> _stopMusicOnEsp() async {
    // 1. Atualiza o estado IMEDIATAMENTE (Assume sucesso)
    setState(() {
      _playingEspId = null;
    });
    
    final url = Uri.parse('$_espIp/stop');
    try {
      final response = await http.post(url); 
      if (response.statusCode == 200) {
        debugPrint('Música parada no ESP!');
      } else {
         debugPrint('Falha ao parar música no ESP: ${response.statusCode}');
         // Não precisa de rollback aqui, pois o estado já foi definido como parado.
      }
    } catch (e) {
      debugPrint('Erro ao parar música: $e');
    }
  }

  // --- WIDGETS DE CONSTRUÇÃO ---

  Widget _buildMusicCard(Map<String, dynamic> music, int index) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final bool isPlaying = _playingEspId == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        elevation: isPlaying ? 8 : 4,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isPlaying 
                ? LinearGradient(
                    colors: [primaryPurple.withOpacity(0.8), primaryPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.white, Colors.grey[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isPlaying ? Colors.white.withOpacity(0.2) : music['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                music['icon'],
                color: isPlaying ? Colors.white : music['color'],
                size: 30,
              ),
            ),
            title: Text(
              music['title'],
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isPlaying ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              music['artist'],
              style: TextStyle(
                color: isPlaying ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            trailing: GestureDetector(
              onTap: () async {
                if (isPlaying) {
                  _stopMusicOnEsp();
                } else {
                  _playMusicOnEsp(music['id'], index); 
                }
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isPlaying ? Colors.white : primaryPurple,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isPlaying ? primaryPurple : Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com informações
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.headphones, color: Colors.white, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Musicoterapia Guiada',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Toque para reproduzir no DoroTEA',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_userMusicList.isNotEmpty) ...[
              _buildSectionTitle('Suas Músicas'),
              ...List.generate(_userMusicList.length, (index) {
                // Os índices de Suas Músicas vão de 0 a _userMusicList.length - 1
                return _buildMusicCard(_userMusicList[index], index);
              }),
            ],

            _buildSectionTitle('Biblioteca Terapêuticakakaka'),
            ...List.generate(_defaultMusicList.length, (index) {
              // Os índices da Biblioteca continuam após as músicas do usuário
              return _buildMusicCard(
                _defaultMusicList[index], 
                _userMusicList.length + index
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Já está na tela atual
              break;
            case 1:
              // Navegar para DoroTEA
              break;
            case 2:
              // Navegar para Perfil
              break;
          }
        },
        items: const [
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