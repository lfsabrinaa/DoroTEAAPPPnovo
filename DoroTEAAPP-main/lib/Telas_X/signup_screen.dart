import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dorotea_app/Telas_X/login_screen.dart';
import 'package:dorotea_app/constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _bearCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Validação em tempo real
  bool _nameValid = false;
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _confirmPasswordValid = false;
  bool _bearCodeValid = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
    
    // Listeners para validação em tempo real
    _fullNameController.addListener(() {
      setState(() {
        _nameValid = _fullNameController.text.trim().isNotEmpty;
      });
    });
    
    _emailController.addListener(() {
      setState(() {
        _emailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(_emailController.text.trim());
      });
    });
    
    _passwordController.addListener(() {
      setState(() {
        _passwordValid = _passwordController.text.length >= 6;
        _confirmPasswordValid = _confirmPasswordController.text == _passwordController.text;
      });
    });
    
    _confirmPasswordController.addListener(() {
      setState(() {
        _confirmPasswordValid = _confirmPasswordController.text == _passwordController.text;
      });
    });
    
    _bearCodeController.addListener(() {
      setState(() {
        _bearCodeValid = _bearCodeController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bearCodeController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool isValid = false,
    String? hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: isValid ? Colors.green : Theme.of(context).primaryColor,
          ),
          suffixIcon: suffixIcon ?? (isValid ? Icon(Icons.check_circle, color: Colors.green) : null),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: isValid ? Colors.green : Colors.grey[300]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: isValid ? Colors.green : Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
        ),
      ),
    );
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final String fullName = _fullNameController.text.trim();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      final String bearCode = _bearCodeController.text.trim();

      final url = Uri.parse('${AppConfig.apiUrl}/cadastro');

      try {
        final response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'nome_completo': fullName,
            'email': email,
            'senha': password,
            'confirme_senha': _confirmPasswordController.text.trim(),
            'codigo_urso': bearCode,
          }),
        );

        if (response.statusCode == 201) {
          _showSuccessDialog();
        } else {
          final errorBody = jsonDecode(response.body);
          String errorMessage = 'Ocorreu um erro. Tente novamente.';
          if (errorBody != null && errorBody['erro'] != null) {
            errorMessage = errorBody['erro'];
          }
          _showErrorSnackBar(errorMessage);
        }
      } catch (e) {
        _showErrorSnackBar('Erro de conexão. Verifique sua internet.');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text(
              'Cadastro realizado!',
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sua conta foi criada com sucesso.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 64, 45, 94),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Fazer Login', style: GoogleFonts.quicksand(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryPurple,
              primaryPurple.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Botão de voltar
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Logo
                  Hero(
                    tag: 'bear_logo',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/bear_logo.png',
                        height: 120,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Título
                  Text(
                    'Criar Conta',
                    style: GoogleFonts.quicksand(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Preencha os dados para se juntar ao DoroTEA',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Card de cadastro
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInputField(
                            controller: _fullNameController,
                            label: 'Nome Completo',
                            icon: Icons.person_outline,
                            isValid: _nameValid,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, digite seu nome completo';
                              }
                              return null;
                            },
                          ),
                          
                          _buildInputField(
                            controller: _emailController,
                            label: 'E-mail',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            isValid: _emailValid,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, digite um email válido';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Por favor, digite um email válido';
                              }
                              return null;
                            },
                          ),
                          
                          _buildInputField(
                            controller: _passwordController,
                            label: 'Senha',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            isValid: _passwordValid,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, digite sua senha';
                              }
                              if (value.length < 6) {
                                return 'A senha deve ter pelo menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          
                          _buildInputField(
                            controller: _confirmPasswordController,
                            label: 'Confirmar Senha',
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            isValid: _confirmPasswordValid && _passwordValid,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, confirme sua senha';
                              }
                              if (value != _passwordController.text) {
                                return 'As senhas não coincidem';
                              }
                              return null;
                            },
                          ),
                          
                          _buildInputField(
                            controller: _bearCodeController,
                            label: 'Código do Urso',
                            icon: Icons.pets,
                            hint: 'Digite o código do seu DoroTEA',
                            isValid: _bearCodeValid,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, digite o código do urso';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // Botão de cadastro
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 64, 45, 94),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'CRIAR CONTA',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Link para login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Já tem uma conta? ',
                        style: GoogleFonts.roboto(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: Text(
                          'Entrar',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}