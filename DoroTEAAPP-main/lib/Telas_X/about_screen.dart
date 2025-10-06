import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dorotea_app/Telas_X/home_screen.dart';
import 'package:dorotea_app/Telas_X/profile_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _selectedIndex = 1; // "DoroTEA" selecionado por padrão
  final Color primaryPurple = Color.fromARGB(255, 181, 154, 230);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(email: 'user@email.com'),
          ),
        );
        break;
      case 1:
        // já estamos na tela About, nada precisa fazer
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(userEmail: 'user@email.com'),
          ),
        );
        break;
    }
  }

  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Não foi possível abrir o link $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DoroTEA',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Ursinho
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(30),
              child: Image.asset(
                'assets/bear_logo.png',
                height: 120,
                width: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 25),
            // Card de explicação
            _buildInfoCard(),
            const SizedBox(height: 25),
            // Botão
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Roboto',
                ),
              ),
              onPressed: () => _openLink('https://www.notion.so/DoroTEA-20c790eced358037b04fd48ca71d46c1?source=copy_link'),
              child: const Text("Confira nossa diário de bordo!"),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "O que é o DoroTEA?",
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "DoroTEA é um projeto desenvolvido para auxiliar "
            "crianças com Transtorno do Espectro Autista (TEA), "
            "atuando como um sistema inteligente de prevenção de crises.",
            style: GoogleFonts.roboto(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureRow(Icons.videocam,
              "Monitora expressões faciais e movimentos por câmeras inteligentes."),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.music_note,
              "Aplica músicas terapêuticas para acalmar a criança durante crises."),
          const SizedBox(height: 12),
          _buildFeatureRow(Icons.favorite,
              "Oferece apoio emocional, criando um ambiente mais acolhedor."),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.roboto(fontSize: 15, height: 1.4),
          ),
        ),
      ],
    );
  }
}
