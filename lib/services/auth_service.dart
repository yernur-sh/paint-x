import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> registerUser(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Обновляем имя пользователя
      await userCredential.user?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e.code);
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'weak-password': return "Пароль слишком слабый!";
      case 'email-already-in-use': return "Этот Email уже зарегистрирован!";
      case 'invalid-email': return "Неверный формат почты";
      case 'user-not-found': return "Пользователь не найден";
      case 'wrong-password': return "Неверный пароль";
      default: return "Произошла ошибка. Попробуйте снова";
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return "Пользователь не найден";
      case 'wrong-password': return "Неверный пароль";
      case 'invalid-email': return "Неверный формат почты";
      case 'user-disabled': return "Аккаунт заблокирован";
      case 'too-many-requests': return "Слишком много попыток. Попробуйте позже";
      default: return "Произошла ошибка при входе";
    }
  }
}