import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart'; // Импорт сервиса

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Подключаем сервис логики
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isFormValid = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _validateForm() {
    if (mounted) {
      setState(() {
        _isFormValid = _nameController.text.isNotEmpty &&
            _isValidEmail(_emailController.text.trim()) &&
            _passwordController.text.length >= 8 &&
            _passwordController.text == _confirmPasswordController.text;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage("Пароли не совпадают!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Вызываем метод из сервиса
      await _authService.registerUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (mounted) {
        _showMessage("Регистрация прошла успешно!");
        Navigator.pop(context);
      }
    } catch (e) {
      // Показываем обработанную ошибку из сервиса
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        SizedBox(height: screenHeight * 0.19),
                        _buildHeader(isTablet),
                        const SizedBox(height: 16),
                        _buildGlassInput(
                          label: "Имя",
                          hint: "Введите ваше имя",
                          controller: _nameController,
                        ),
                        const SizedBox(height: 12),
                        _buildGlassInput(
                          label: "E-mail",
                          hint: "Ваша электронная почта",
                          controller: _emailController,
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 12),
                        _buildGlassInput(
                          label: "Пароль",
                          hint: "Минимум 8 символов",
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 12),
                        _buildGlassInput(
                          label: "Подтверждение пароля",
                          hint: "Повторите пароль",
                          isPassword: true,
                          controller: _confirmPasswordController,
                        ),
                        const Spacer(),
                        const SizedBox(height: 20),
                        _buildRegisterButton(screenWidth, screenHeight, isTablet),
                        const SizedBox(height: 16),
                        _buildFooter(),
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

  // ДИЗАЙН-ВИДЖЕТЫ ОСТАЛИСЬ ПРЕЖНИМИ
  Widget _buildHeader(bool isTablet) {
    double fontSize = isTablet ? 26 : 20;
    return Stack(
      children: [
        Text("Регистрация", style: GoogleFonts.pressStart2p(fontSize: fontSize, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFF8E2DE2).withOpacity(0.7))),
        Text("Регистрация", style: GoogleFonts.pressStart2p(fontSize: fontSize, color: Colors.white)),
      ],
    );
  }

  Widget _buildRegisterButton(double screenWidth, double screenHeight, bool isTablet) {
    return GestureDetector(
      onTap: _isFormValid && !_isLoading ? _registerUser : null,
      child: Container(
        width: double.infinity,
        height: (screenHeight * 0.07).clamp(50, 65),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _isFormValid
              ? const LinearGradient(colors: [Color(0xFF8924E7), Color(0xFF6A46F9)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              : null,
          color: _isFormValid ? null : const Color(0xFF87858F),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text("Зарегистрироваться", style: TextStyle(fontSize: isTablet ? 20 : 18, fontWeight: FontWeight.bold, color: _isFormValid ? Colors.white : const Color(0xFF404040))),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Уже есть аккаунт? Войти", style: TextStyle(color: Colors.white54))),
    );
  }

  Widget _buildGlassInput({required String label, required String hint, bool isPassword = false, required TextEditingController controller}) {
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
              suffixIcon: isPassword ? IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white24, size: 20), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)) : null,
            ),
          ),
        ],
      ),
    );
  }
}