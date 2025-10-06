import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dorotea_app/screens/add_music_screen.dart';
import 'package:dorotea_app/Telas_X/profile_screen.dart';
import 'package:dorotea_app/Telas_X/about_screen.dart';
import 'package:dorotea_app/Telas_X/home_screen.dart';
import 'package:dorotea_app/constants.dart'; // apiUrl

class MusicSelectionScreen extends StatefulWidget {
  final String email;
  const MusicSelectionScreen({super.key, required this.email});

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  final List<Map<String, dynamic>> _defaultMusicList = [
    {
      'id': 'bmp',
      'title': '60 BPM',
      'artist': 'Anônimo',
      'audioUrl': 'assets/audios/bmp.mp3',
      'isDeletable': false,
    },
    {
      'id': 'brilha_estrelinha',
      'title': 'Brilha Estrelinha',
      'artist': 'Anônimo',
      'audioUrl': 'assets/audios/brilha_brilha_estrelinha.mp3',
      'isDeletable': false,
    },
    {
      'id': 'clair_de_lune',
      'title': 'Clair de Lune',
      'artist': 'Claude Debussy',
      'audioUrl': 'assets/audios/clair_de_lune.mp3',
      'isDeletable': false,
    },
    {
      'id': 'lullaby',
      'title': 'Lullaby',
      'artist': 'Johannes Brahms',
      'audioUrl': 'assets/audios/lullaby.mp3',
      'isDeletable': false,
    },
    {
      'id': 'primavera',
      'title': 'Primavera',
      'artist': 'Vivaldi',
      'audioUrl': 'assets/audios/primavera.mp3',
      'isDeletable': false,
    },
  ];

  late List<Map<String, dynamic>> _userMusicList;
  final _player = AudioPlayer();
  int? _playingIndex;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _userMusicList = [];
    _loadUserMusic();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen(email: 'user@email.com')),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userEmail: widget.email),
          ),
        );
        break;
    }
  }

  // ✅ Corrigido: retorna Future<void> para RefreshIndicator
  Future<void> _loadUserMusic() async {
    final String userEmail = widget.email;
    if (userEmail.isEmpty) {
      debugPrint('Usuário não logado.');
      return;
    }

    final url = Uri.parse('${AppConfig.apiUrl}/musics/$userEmail');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> fetchedMusics = data['musics'];
        final List<Map<String, dynamic>> userMusics =
            List<Map<String, dynamic>>.from(fetchedMusics.map((music) {
          return {
            'id': music['id'].toString(),
            'title': music['title'] ?? 'Sem Título',
            'artist': music['artist'] ?? 'Sem Artista',
            'audioUrl': music['audioUrl'] ?? '',
            'isDeletable': music['isDeletable'] ?? true,
          };
        }));
        setState(() {
          _userMusicList = userMusics;
        });
        debugPrint('Músicas do usuário carregadas com sucesso.');
      } else {
        debugPrint('Erro ao carregar músicas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro de conexão ao carregar músicas: $e');
    }
  }

  Future<void> _deleteMusic(String musicId) async {
    final url = Uri.parse('${AppConfig.apiUrl}/delete_music/$musicId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Música deletada com sucesso!')),
          );
        }
        await _loadUserMusic();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao deletar música.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao deletar música: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão ao deletar música.')),
        );
      }
    }
  }

  Future<void> _playMusic(String audioUrl, int index) async {
    try {
      if (_player.playing) {
        await _player.stop();
      }
      if (audioUrl.startsWith('assets/')) {
        await _player.setAsset(audioUrl);
      } else {
        await _player.setUrl(audioUrl);
      }
      await _player.play();
      setState(() {
        _playingIndex = index;
      });
      _player.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          setState(() {
            _playingIndex = null;
          });
        }
      });
    } catch (e) {
      debugPrint('Erro ao tocar música: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao tocar música. Verifique o URL.')),
        );
      }
    }
  }

  void _pauseMusic() {
    _player.pause();
    setState(() {
      _playingIndex = null;
    });
  }

  Widget _buildMusicSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.quicksand(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMusicItem(BuildContext context, Map<String, dynamic> music, int index) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final bool isPlaying = _playingIndex == index;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: ListTile(
        leading: Icon(
          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
          color: primaryPurple,
          size: 40,
        ),
        title: Text(
          music['title'] ?? 'Título Desconhecido',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          music['artist'] ?? 'Artista Desconhecido',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: music['isDeletable'] ?? false
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _deleteMusic(music['id'].toString());
                },
              )
            : null,
        onTap: () async {
          if (isPlaying) {
            _pauseMusic();
          } else {
            _playMusic(music['audioUrl'], index);
          }
        },
      ),
    );
  }

  Widget _buildAddMusicCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Adicionar música',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF673AB7),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF673AB7)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMusicScreen(email: widget.email),
                ),
              ).then((_) {
                _loadUserMusic();
              });
            },
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
      body: RefreshIndicator(
        onRefresh: _loadUserMusic, // ✅ corrigido
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddMusicCard(),
              _buildMusicSectionHeader('Músicas do Usuário'),
              if (_userMusicList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Nenhuma música adicionada ainda.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userMusicList.length,
                  itemBuilder: (context, index) {
                    final music = _userMusicList[index];
                    return _buildMusicItem(context, music, index);
                  },
                ),
              _buildMusicSectionHeader('Músicas Padrão'),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _defaultMusicList.length,
                itemBuilder: (context, index) {
                  final music = _defaultMusicList[index];
                  return _buildMusicItem(
                      context, music, _userMusicList.length + index);
                },
              ),
            ],
          ),
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