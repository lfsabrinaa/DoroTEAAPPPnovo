// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:dorotea_app/Telas_X/initial_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dorotea_app/Telas_X/about_screen.dart';
import 'package:dorotea_app/Telas_X/home_screen.dart';
import 'package:dorotea_app/constants.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;
  const ProfileScreen({super.key, required this.userEmail});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = 'Carregando...';
  String _email = 'Carregando...';
  String _bearCode = 'Carregando...';
  bool _isLoading = true;
  int _selectedIndex = 2; // Índice para a tela de Perfil

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final url = Uri.parse('${AppConfig.apiUrl}/usuario/${widget.userEmail}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          _fullName = userData['nome_completo'] ?? 'Não informado';
          _email = userData['email'] ?? 'Não informado';
          _bearCode = userData['codigo_urso'] ?? 'Não informado';
          _isLoading = false;
        });
      } else {
        setState(() {
          _fullName = 'Erro ao carregar';
          _email = 'Erro ao carregar';
          _bearCode = 'Erro ao carregar';
          _isLoading = false;
        });
        debugPrint('Erro ao carregar perfil: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _fullName = 'Erro de conexão';
        _email = 'Erro de conexão';
        _bearCode = 'Erro de conexão';
        _isLoading = false;
      });
      debugPrint('Erro de conexão ao carregar perfil: $e');
    }
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
    }
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const InitialScreen()),
      (Route<dynamic> route) => false,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF673AB7), // Roxo mais escuro para o ícone
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildProfileInfoRow(
                          context,
                          icon: Icons.email,
                          label: 'Email',
                          value: _email,
                        ),
                        _buildDivider(),
                        _buildProfileInfoRow(
                          context,
                          icon: Icons.pets,
                          label: 'Código do Urso',
                          value: _bearCode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 15.0),
                    ),
                    child: const Text('SAIR'),
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

  Widget _buildProfileInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryPurple),
          const SizedBox(width: 15.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: primaryPurple,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1.0,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
    );
  }
}