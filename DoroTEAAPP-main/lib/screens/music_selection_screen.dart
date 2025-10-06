import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'dart:convert';
import 'package:dorotea_app/screens/add_music_screen.dart';
import 'package:dorotea_app/Telas_X/profile_screen.dart';
import 'package:dorotea_app/Telas_X/about_screen.dart';
import 'package:dorotea_app/Telas_X/home_screen.dart';
import 'package:dorotea_app/constants.dart';

class MusicSelectionScreen extends StatefulWidget {
  final String email;
  const MusicSelectionScreen({super.key, required this.email});

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _defaultMusicList = [
    {
      'id': 'dorotea',
      'title': 'DoroTEA',
      'artist': '3403',
      'audioUrl': 'assets/audios/DoroTEA.mp3',
      'isDeletable': false,
    },
    {
      'id': 'clair_de_lune',
      'title': 'Clair de Lune',
      'artist': 'Claude Debussy',
      'audioUrl': 'assets/audios/clairedelune.mp3',
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
      'id': 'brilha_estrelinha',
      'title': 'Brilha Estrelinha',
      'artist': 'Anônimo',
      'audioUrl': 'assets/audios/bbee.mp3',
      'isDeletable': false,
    },
    {
      'id': 'bmp',
      'title': '60 BPM',
      'artist': 'Anônimo',
      'audioUrl': 'assets/audios/bmp.mp3',
      'isDeletable': false,
    },
  ];

  List<Map<String, dynamic>> _userMusicList = [];
  final _player = AudioPlayer();
  int? _playingIndex;
  int _selectedIndex = 0;
  bool _isLoading = true;
  late TabController _tabController;
  String? _selectedMusicId; // ID da música selecionada como padrão

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserMusic();
  }

  @override
  void dispose() {
    _player.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserMusic() async {
    setState(() => _isLoading = true);
    
    try {
      final url = '${AppConfig.apiUrl}/downloadable_files';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> musicList = data['musics'] ?? [];
        
        setState(() {
          _userMusicList = musicList.map<Map<String, dynamic>>((music) => {
            'id': music['filename']?.toString() ?? '',
            'title': _extractTitle(music['filename']?.toString() ?? ''),
            'artist': _extractArtist(music['filename']?.toString() ?? ''),
            'audioUrl': music['url']?.toString() ?? '',
            'isDeletable': true,
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _userMusicList = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _userMusicList = [];
        _isLoading = false;
      });
    }
  }

  String _extractTitle(String filename) {
    final nameWithoutExt = filename.replaceAll(RegExp(r'\.[^.]+$'), '');
    final parts = nameWithoutExt.split('_');
    return parts.length > 1 ? parts.sublist(1).join(' ') : nameWithoutExt;
  }
  
  String _extractArtist(String filename) {
    final nameWithoutExt = filename.replaceAll(RegExp(r'\.[^.]+$'), '');
    final parts = nameWithoutExt.split('_');
    return parts.isNotEmpty ? parts[0] : 'Desconhecido';
  }

  Future<void> _playMusic(String audioUrl, int index, bool isUserMusic) async {
    try {
      await _player.stop();
      if (audioUrl.startsWith('assets/')) {
        await _player.setAsset(audioUrl);
      } else {
        await _player.setUrl(audioUrl);
      }
      await _player.play();
      setState(() => _playingIndex = isUserMusic ? index : index + 1000);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao tocar música')),
      );
    }
  }

  void _pauseMusic() {
    _player.pause();
    setState(() => _playingIndex = null);
  }

  Future<void> _deleteMusic(String filename) async {
    try {
      final response = await http.delete(Uri.parse('${AppConfig.apiUrl}/delete_music/$filename'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Música deletada com sucesso!')),
        );
        // Se a música deletada era a selecionada, limpa a seleção
        if (_selectedMusicId == filename) {
          setState(() {
            _selectedMusicId = null;
          });
        }
        _loadUserMusic();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao deletar música')),
      );
    }
  }

  Future<void> _saveSelectedMusic(String musicId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/set_default_music'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'music_id': musicId,
        }),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Música padrão definida!')),
        );
      }
    } catch (e) {
      print('Erro ao salvar música padrão: $e');
    }
  }

  Widget _buildMusicItem(Map<String, dynamic> music, int index, bool isUserMusic) {
    final playIndex = isUserMusic ? index : index + 1000;
    final isPlaying = _playingIndex == playIndex;
    final isSelected = _selectedMusicId == music['id'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected 
              ? [const Color(0xFFE1BEE7), const Color(0xFFF3E5F5)] 
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: isSelected 
            ? Border.all(color: const Color(0xFF4A148C), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A148C).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF4A148C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: const Color(0xFF4A148C),
              size: 28,
            ),
            onPressed: () {
              if (isPlaying) {
                _pauseMusic();
              } else {
                _playMusic(music['audioUrl'], index, isUserMusic);
              }
            },
          ),
        ),
        title: Row(
          children: [
            Radio<String>(
              value: music['id'],
              groupValue: _selectedMusicId,
              onChanged: (String? value) {
                setState(() {
                  _selectedMusicId = value;
                });
                _saveSelectedMusic(value!);
              },
              activeColor: const Color(0xFF4A148C),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    music['title'],
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF2E2E2E),
                    ),
                  ),
                  Text(
                    music['artist'],
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: music['isDeletable']
            ? IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 24),
                onPressed: () => _deleteMusic(music['id']),
              )
            : (isSelected 
                ? const Icon(Icons.star, color: Color(0xFF4A148C), size: 24)
                : Icon(Icons.music_note_rounded, color: Colors.grey[400])),
      ),
    );
  }

  Widget _buildUserMusicTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddMusicScreen(email: widget.email)),
            ).then((_) => _loadUserMusic()),
            icon: const Icon(Icons.add_rounded),
            label: Text('Adicionar Música', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A148C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A148C)))
              : _userMusicList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_off_rounded, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma música adicionada',
                            style: GoogleFonts.quicksand(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _userMusicList.length,
                      itemBuilder: (context, index) {
                        return _buildMusicItem(_userMusicList[index], index, true);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDefaultMusicTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _defaultMusicList.length,
      itemBuilder: (context, index) {
        return _buildMusicItem(_defaultMusicList[index], index, false);
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, 
          MaterialPageRoute(builder: (context) => HomeScreen(email: widget.email)));
        break;
      case 1:
        Navigator.pushReplacement(context, 
          MaterialPageRoute(builder: (context) => const AboutScreen()));
        break;
      case 2:
        Navigator.pushReplacement(context, 
          MaterialPageRoute(builder: (context) => ProfileScreen(userEmail: widget.email)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text(
          'DoroTEA',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'Músicas Padrão'),
            Tab(text: 'Minhas Músicas'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDefaultMusicTab(),
            _buildUserMusicTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'DoroTEA'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}