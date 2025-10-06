import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:dorotea_app/Telas_X/profile_screen.dart';
import 'package:dorotea_app/Telas_X/about_screen.dart';
import 'package:dorotea_app/Telas_X/home_screen.dart';

class CameraScreen extends StatefulWidget {
  final String email;
  const CameraScreen({super.key, required this.email});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  int _selectedIndex = 1;

  late VlcPlayerController _vlcController;

  @override
  void initState() {
    super.initState();

    _vlcController = VlcPlayerController.network(
      'rtsp://192.168.0.10:554/stream', // URL RTSP da sua câmera
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
  }

  @override
  void dispose() {
    _vlcController.stop();
    _vlcController.dispose();
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
          MaterialPageRoute(
              builder: (context) => HomeScreen(email: widget.email)),
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

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DoroTEA',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryPurple,
      ),
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: SizedBox(
            width: 350,
            height: 250,
            child: VlcPlayer(
              controller: _vlcController,
              aspectRatio: 16 / 9,
              placeholder: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
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
