import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dorotea_app/Telas_X/profile_screen.dart';
import 'package:dorotea_app/Telas_X/about_screen.dart';
import 'package:dorotea_app/screens/music_selection_screen.dart';
import 'package:dorotea_app/screens/report_screen.dart';
import 'package:dorotea_app/screens/camera_screen.dart'; // Importe a tela da câmera
import 'package:dorotea_app/screens/guide_music_redesign.dart'; // Importe a nova tela

class HomeScreen extends StatefulWidget {
  final String email;
  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<Map<String, dynamic>> _featureCards;
  final List<bool> _isPressed = [false, false, false, false];
  late AnimationController _staggerController;
  late List<Animation<Offset>> _slideAnimations;
  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconAnimations;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia!';
    if (hour < 18) return 'Boa tarde!';
    return 'Boa noite!';
  }

  @override
  void initState() {
    super.initState();
    
    // Animação de entrada dos cards
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Controllers para animação dos ícones
    _iconControllers = List.generate(4, (index) => 
      AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      )
    );
    
    // Animações de slide para cada card
    _slideAnimations = List.generate(4, (index) => 
      Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          index * 0.2,
          0.8 + (index * 0.05),
          curve: Curves.easeOutCubic,
        ),
      ))
    );
    
    // Animações de rotação para os ícones
    _iconAnimations = _iconControllers.map((controller) => 
      Tween<double>(begin: 0, end: 0.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut)
      )
    ).toList();
    
    _featureCards = [
      {
        'icon': Icons.camera_alt,
        'title': 'Visualizar Agora',
        'description': 'Acompanhe em tempo real como está seu pequeno',
        'onTap': () {
          // Ação para a tela da câmera
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(email: widget.email),
            ),
          );
        },
      },
      {
        'icon': Icons.music_note,
        'title': 'Escolher Música',
        'description': 'Escolha a música que o ursinho Dorotea vai tocar',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MusicSelectionScreen(email: widget.email),
            ),
          );
        },
      },
      {
        'icon': Icons.headphones, // Novo ícone para musicoterapia guiada
        'title': 'Terapia Guiada',
        'description': 'Inicie uma sessão de musicoterapia guiada com o Dorotea',
        'onTap': () {
          // Ação para a tela de musicoterapia guiada
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuidedMusic(email: widget.email),
            ),
          );
        },
      },
      {
        'icon': Icons.assignment,
        'title': 'Relatórios de Humor',
        'description': 'Entenda como tem sido os últimos dias',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportScreen(userEmail: widget.email),
            ),
          );
        },
      },
    ];
    
    // Inicia animação de entrada
    _staggerController.forward();
  }
  
  @override
  void dispose() {
    _staggerController.dispose();
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        debugPrint('Home clicado!');
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
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              'DoroTEA',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 80,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: List.generate(_featureCards.length, (index) {
            final cardData = _featureCards[index];
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _staggerController,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() => _isPressed[index] = true);
                      _iconControllers[index].forward();
                    },
                    onTapUp: (_) {
                      setState(() => _isPressed[index] = false);
                      _iconControllers[index].reverse();
                      cardData['onTap']();
                    },
                    onTapCancel: () {
                      setState(() => _isPressed[index] = false);
                      _iconControllers[index].reverse();
                    },
                    child: AnimatedScale(
                      scale: _isPressed[index] ? 0.97 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      child: _buildFeatureCard(
                        icon: cardData['icon'],
                        title: cardData['title'],
                        description: cardData['description'],
                        primaryPurple: primaryPurple,
                        lightPurpleText: lightPurpleText,
                        iconAnimation: _iconAnimations[index],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color primaryPurple,
    required Color lightPurpleText,
    required Animation<double> iconAnimation,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: iconAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: iconAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: primaryPurple.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Icon(
                    icon,
                    size: 40.0,
                    color: primaryPurple,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    color: lightPurpleText,
                    fontSize: 19.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    color: Colors.grey[700],
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward,
            color: lightPurpleText,
          ),
        ],
      ),
    );
  }
}