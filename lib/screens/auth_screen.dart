import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hh_test/screens/register_screen.dart';
import '../services/auth_service.dart'; // Импорт логики

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Инициализация сервиса логики
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Валидация Email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Метод входа (теперь он стал коротким и понятным)
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isValidEmail(email)) {
      _showError("Неверный формат Email");
      return;
    }

    if (password.length < 8) {
      _showError("Пароль должен содержать минимум 8 символов");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Вызываем логику из сервиса
      await _authService.signIn(email, password);
    } catch (e) {
      // Показываем ошибку, которую вернул сервис
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Показ SnackBar
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Весь твой UI остается без изменений
    final size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.30),
                        _buildHeader(isTablet),
                        const SizedBox(height: 14),
                        _buildGlassInput(
                          label: "E-mail",
                          hint: "Введите электронную почту",
                          controller: _emailController,
                          screenWidth: screenWidth,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassInput(
                          label: "Пароль",
                          hint: "Введите пароль",
                          isPassword: true,
                          controller: _passwordController,
                          screenWidth: screenWidth,
                        ),
                        const Spacer(),
                        const SizedBox(height: 20),
                        _buildMainButton(screenWidth, screenHeight, isTablet),
                        const SizedBox(height: 16),
                        _buildRegisterButton(screenWidth, screenHeight, isTablet),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Твои оригинальные виджеты (дизайн)
  Widget _buildHeader(bool isTablet) {
    double fontSize = isTablet ? 32 : 25;
    return Stack(
      children: [
        Text("Вход", style: GoogleFonts.pressStart2p(fontSize: fontSize, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFF8E2DE2).withOpacity(0.7))),
        Text("Вход", style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: fontSize)),
      ],
    );
  }

  Widget _buildMainButton(double screenWidth, double screenHeight, bool isTablet) {
    return Container(
      width: double.infinity,
      height: (screenHeight * 0.07).clamp(50, 65),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Войти", style: TextStyle(color: Colors.white, fontSize: isTablet ? 22 : 20)),
      ),
    );
  }

  Widget _buildRegisterButton(double screenWidth, double screenHeight, bool isTablet) {
    return SizedBox(
      width: double.infinity,
      height: (screenHeight * 0.07).clamp(50, 65),
      child: ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen())),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0E0E0), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text("Регистрация", style: TextStyle(fontSize: isTablet ? 22 : 20)),
      ),
    );
  }

  Widget _buildGlassInput({required String label, required String hint, bool isPassword = false, required TextEditingController controller, required double screenWidth}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          TextField(
            controller: controller,
            obscureText: isPassword ? !_isPasswordVisible : false,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: isPassword ? IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white54, size: 20), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)) : null,
            ),
          ),
        ],
      ),
    );
  }
}