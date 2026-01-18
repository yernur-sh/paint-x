import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GalleryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Получение текущего пользователя
  User? get currentUser => _auth.currentUser;

  // Выход из системы
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Стрим только для галереи
  Stream<QuerySnapshot> getGalleryStream() {
    final user = _auth.currentUser;
    return _firestore
        .collection('gallery')
        .where('author_id', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Удаление только для галереи
  Future<void> deleteImage(String docId) async {
    try {
      await _firestore.collection('gallery').doc(docId).delete();
    } catch (e) {
      throw "Не удалось удалить изображение";
    }
  }
}