import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hh_test/screens/painter_screen.dart';
import '../services/gallery_service.dart';
import 'edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Инициализируем наш сервис логики
  final GalleryService _authService = GalleryService();
  int? selectedIndex;

  // Удаление через сервис
  Future<void> _deleteImage(String docId) async {
    try {
      await _authService.deleteImage(docId);
      setState(() => selectedIndex = null);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // Диалог подтверждения выхода
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Выход"),
        content: const Text("Вы действительно хотите выйти из аккаунта?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Нет")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authService.signOut(); // Выход через сервис
            },
            child: const Text("Да", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Диалог подтверждения удаления
  void _showDeleteDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Удаление"),
        content: const Text("Вы действительно хотите удалить это изображение?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Нет")),
          TextButton(
            onPressed: () {
              _deleteImage(docId);
              Navigator.pop(context);
            },
            child: const Text("Да", style: TextStyle(color: Colors.red)),
          ),
        ],
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
      appBar: _buildAppBar(screenWidth, isTablet),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildGalleryGrid(screenWidth, isTablet)),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.02
              ),
              child: _buildCreateButton(screenWidth, screenHeight),
            ),
          ],
        ),
      ),
    );
  }

  // --- Дизайн-виджеты (без изменений дизайна) ---

  PreferredSizeWidget _buildAppBar(double screenWidth, bool isTablet) {
    return PreferredSize(
      preferredSize: Size.fromHeight(isTablet ? 90 : 80),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: AppBar(
            toolbarHeight: 102,
            backgroundColor: const Color(0xFF604490).withOpacity(0.3),
            elevation: 0,
            centerTitle: true,
            leading: _buildLogoutButton(screenWidth, isTablet),
            title: Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Text(
                "Галерея",
                style: GoogleFonts.roboto(fontSize: isTablet ? 26 : 20, color: Colors.white),
              ),
            ),
            actions: [
              if (selectedIndex != null) _buildDeleteAction(screenWidth, isTablet),
              SizedBox(width: screenWidth * 0.02),
              _buildEditAction(screenWidth, isTablet),
              SizedBox(width: screenWidth * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(double screenWidth, bool isTablet) {
    return InkWell(
      onTap: _showLogoutDialog,
      child: Padding(
        padding: EdgeInsets.only(top: 25, left: screenWidth * 0.04),
        child: Transform.scale(scale: isTablet ? 1.0 : 0.8, child: SvgPicture.asset('images/logout.svg')),
      ),
    );
  }

  Widget _buildDeleteAction(double screenWidth, bool isTablet) {
    return StreamBuilder<QuerySnapshot>(
      stream: _authService.getGalleryStream(), // Стрим из сервиса
      builder: (context, snapshot) {
        return IconButton(
          onPressed: () {
            if (snapshot.hasData && selectedIndex != null) {
              _showDeleteDialog(snapshot.data!.docs[selectedIndex!].id);
            }
          },
          icon: Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Transform.scale(scale: isTablet ? 1.5 : 1.3, child: SvgPicture.asset('images/delete.svg')),
          ),
        );
      },
    );
  }

  Widget _buildEditAction(double screenWidth, bool isTablet) {
    return StreamBuilder<QuerySnapshot>(
      stream: _authService.getGalleryStream(), // Стрим из сервиса
      builder: (context, snapshot) {
        return InkWell(
          onTap: () {
            if (selectedIndex != null && snapshot.hasData) {
              final doc = snapshot.data!.docs[selectedIndex!];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditScreen(initialBase64: doc['image_data'], docId: doc.id),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Transform.scale(scale: isTablet ? 1.5 : 1.3, child: SvgPicture.asset('images/edit.svg')),
          ),
        );
      },
    );
  }

  Widget _buildGalleryGrid(double screenWidth, bool isTablet) {
    return StreamBuilder<QuerySnapshot>(
      stream: _authService.getGalleryStream(), // Стрим из сервиса
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text("Галерея пуста", style: TextStyle(color: Colors.white54)));
        }

        return GridView.builder(
          padding: EdgeInsets.all(screenWidth * 0.05),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            crossAxisSpacing: screenWidth * 0.04,
            mainAxisSpacing: screenWidth * 0.04,
            childAspectRatio: 1.0,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final String base64String = docs[index]['image_data'] ?? '';
            return InkWell(
              onTap: () => setState(() {
                selectedIndex = (selectedIndex == index) ? null : index;
              }),
              child: _buildGalleryItem(base64String, selectedIndex == index, screenWidth),
            );
          },
        );
      },
    );
  }

  Widget _buildGalleryItem(String base64String, bool isSelected, double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        border: Border.all(
          color: isSelected ? const Color(0xFF8924E7) : Colors.white.withOpacity(0.3),
          width: isSelected ? 3 : 1,
        ),
        boxShadow: [
          if (isSelected) BoxShadow(color: const Color(0xFF8924E7).withOpacity(0.4), blurRadius: 10)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screenWidth * 0.045),
        child: base64String.isNotEmpty
            ? Image.memory(base64Decode(base64String), fit: BoxFit.cover)
            : const Icon(Icons.image, color: Colors.white24),
      ),
    );
  }

  Widget _buildCreateButton(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      height: screenHeight * 0.06,
      constraints: const BoxConstraints(minHeight: 50, maxHeight: 70),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8924E7), Color(0xFF6A46F9)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PainterScreen())),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text("Создать", style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold)),
      ),
    );
  }
}