import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dorotea_app/Telas_X/profile_screen.dart';
import 'package:dorotea_app/Telas_X/about_screen.dart';
import 'package:dorotea_app/Telas_X/home_screen.dart';

import 'package:dorotea_app/constants.dart'; 



class AddMusicScreen extends StatefulWidget {
  final String email;
  const AddMusicScreen({super.key, required this.email});

  @override
  State<AddMusicScreen> createState() => _AddMusicScreenState();
}

class _AddMusicScreenState extends State<AddMusicScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  File? _selectedFile;
  String _fileName = 'Selecione um arquivo MP3';
  bool _isLoading = false;
  int _selectedIndex = 0;

  // Estilo customizado para os TextFields (mantendo o design original)
  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  // Lógica para selecionar o arquivo
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = path.basename(_selectedFile!.path);
      });
    } else {
      setState(() {
        _selectedFile = null;
        _fileName = 'Selecione um arquivo MP3';
      });
    }
  }

  // Lógica para enviar a música
  Future<void> _addMusic() async {
    if (_isLoading) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um arquivo de áudio.')),
      );
      return;
    }

    // Aplica .trim() para limpar possíveis espaços vazios no início/fim
    final String title = _titleController.text.trim();
    final String artist = _artistController.text.trim();
    // ESSENCIAL: Garante que o email não tem espaços, resolvendo o 404/Usuário não encontrado
    final String userEmail = widget.email.trim(); 

    if (title.isEmpty || artist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o título e o artista.')),
      );
      return;
    }
    
    // Verifica se o email está vazio. Se estiver, o problema é na tela anterior.
    if (userEmail.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: O email do usuário não foi fornecido.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    // A string da API é construída com AppConfig.apiUrl (se você tiver)
    // Se não tiver, use 'http://SEU_IP:5000/add_music'.
    // NOTE: A API usa 'file' para o arquivo e 'email', 'title', 'artist' para os campos.
    final String apiUrl = '${AppConfig.apiUrl}/add_music'; 

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(apiUrl.trim()), // Garante que não há espaços na URL
    );

    try {
      final String? mimeType = lookupMimeType(_selectedFile!.path);

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _selectedFile!.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));

      // Adiciona os campos de formulário
      request.fields['email'] = userEmail;
      request.fields['title'] = title;
      request.fields['artist'] = artist;
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (mounted) {
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Música adicionada com sucesso!')),
          );
          Navigator.pop(context); // Volta para a tela anterior
        } else {
          // Trata erros da API como o 404 (Usuário não encontrado)
          final Map<String, dynamic> errorData = json.decode(responseBody);
          String errorMessage = errorData['erro'] ?? 'Erro desconhecido';
          
          if (response.statusCode == 404) {
             errorMessage = 'Usuário não encontrado. Verifique seu login ou se o email: "$userEmail" existe no servidor.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ${response.statusCode}: $errorMessage'),
            ),
          );
          debugPrint('Corpo do erro: $responseBody');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão. Verifique o IP do servidor e sua rede.')),
        );
        debugPrint('Erro de conexão: $e');
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
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
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Campos de Texto com o Container customizado
            _buildInputField(
              controller: _titleController,
              labelText: 'Título da Música',
              icon: Icons.music_note,
            ),
            _buildInputField(
              controller: _artistController,
              labelText: 'Nome do Artista',
              icon: Icons.person,
            ),

            const SizedBox(height: 16.0),

            // Seleção de Arquivo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _fileName,
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickFile,
                    icon: Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                    label: const Text('Selecionar Arquivo'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48.0),

            // Botão Adicionar Música
            ElevatedButton(
              onPressed: _isLoading ? null : _addMusic,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 64, 45, 94),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : Text(
                      'Adicionar Música',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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