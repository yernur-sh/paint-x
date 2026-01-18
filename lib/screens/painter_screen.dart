import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PainterScreen extends StatefulWidget {
  const PainterScreen({super.key});

  @override
  State<PainterScreen> createState() => _PainterScreenState();
}

class _PainterScreenState extends State<PainterScreen> {
  String activeTool = 'brush';
  List<DrawingPoint?> points = [];
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;
  final GlobalKey _canvasKey = GlobalKey();
  ui.Image? backgroundImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<List<DrawingPoint?>> redoHistory = [];

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  // Хабарламаларды инициализациялау
  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);
  }

  // Сәтті сақталғаны туралы хабарлама
  Future<void> _showSuccessNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'save_status_channel', 'Статус сохранения',
      importance: Importance.max, priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _notificationsPlugin.show(0, 'Успешно!', 'Изображение сохранено в облако и галерею', details);
  }

  @override
  Widget build(BuildContext context) {
    // Экран өлшемдерін алу
    final size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(screenWidth, isTablet),
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.025),
          _buildToolbar(screenWidth, isTablet),
          SizedBox(height: screenHeight * 0.025),
          _buildCanvasArea(screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.04),
        ],
      ),
    );
  }

  // Адаптивті AppBar
  PreferredSizeWidget _buildAppBar(double screenWidth, bool isTablet) {
    return PreferredSize(
      preferredSize: Size.fromHeight(isTablet ? 95 : 85),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: AppBar(
            toolbarHeight: 102,
            backgroundColor: const Color(0xFF604490).withOpacity(0.3),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              padding: const EdgeInsets.only(top: 25),
              icon: Transform.scale(
                  scale: isTablet ? 1.5 : 1.3,
                  child: SvgPicture.asset('images/back.svg')
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Text(
                  "Новое изображение",
                  style: GoogleFonts.roboto(fontSize: isTablet ? 24 : 18, color: Colors.white)
              ),
            ),
            actions: [
              _isLoading
                  ? const Padding(
                padding: EdgeInsets.only(top: 25, right: 15),
                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
              )
                  : IconButton(
                padding: const EdgeInsets.only(top: 25, right: 10),
                icon: Transform.scale(scale: isTablet ? 1.3 : 1.1, child: SvgPicture.asset('images/save.svg')),
                onPressed: _saveToFirestoreOnly,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Адаптивті Toolbar
  Widget _buildToolbar(double screenWidth, bool isTablet) {
    double scale = isTablet ? 1.8 : 1.3;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Row(
        children: [
          _buildToolItem('undo', Icons.undo, scale),
          _buildToolItem('redo', Icons.redo, scale),
          _buildToolItem('size', Icons.line_weight, scale),
          _buildToolItem('download', 'images/down.svg', scale),
          _buildToolItem('image', 'images/image.svg', scale),
          _buildToolItem('brush', 'images/brush.svg', scale),
          _buildToolItem('eraser', 'images/eraser.svg', scale),
          _buildToolItem('palette', 'images/palette.svg', scale),
        ].expand((w) => [w, SizedBox(width: screenWidth * 0.035)]).toList()..removeLast(),
      ),
    );
  }

  Widget _buildToolItem(String toolName, dynamic iconOrAsset, double scale) {
    bool isActive = activeTool == toolName;
    return GestureDetector(
      onTap: () {
        if (toolName == 'undo') _undo();
        else if (toolName == 'redo') _redo();
        else if (toolName == 'size') _showSizePicker();
        else if (toolName == 'download') _saveCanvas();
        else if (toolName == 'image') _importImage();
        else if (toolName == 'palette') _showColorPicker();
        else setState(() => activeTool = toolName);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Transform.scale(
          scale: scale,
          child: iconOrAsset is IconData
              ? Icon(iconOrAsset, size: 25, color: Colors.white.withOpacity(0.8))
              : SvgPicture.asset(
            iconOrAsset,
            colorFilter: ColorFilter.mode(
                isActive ? Colors.white : Colors.white.withOpacity(0.5),
                BlendMode.srcIn
            ),
          ),
        ),
      ),
    );
  }

  // Адаптивті Холст аймағы
  Widget _buildCanvasArea(double screenWidth, double screenHeight) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: screenHeight * 0.1),
        child: RepaintBoundary(
          key: _canvasKey,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: GestureDetector(
                onPanStart: (d) => setState(() { redoHistory.clear(); _addPoint(d.localPosition); }),
                onPanUpdate: (d) => setState(() => _addPoint(d.localPosition)),
                onPanEnd: (d) => setState(() => points.add(null)),
                child: CustomPaint(
                  painter: MyPainter(pointsList: points, bgImage: backgroundImage),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Функциялар ---

  void _addPoint(Offset localPos) {
    points.add(DrawingPoint(
      offset: localPos,
      paint: Paint()
        ..color = activeTool == 'eraser' ? Colors.white : selectedColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = activeTool == 'eraser' ? strokeWidth * 2.5 : strokeWidth,
    ));
  }

  Future<void> _saveToFirestoreOnly() async {
    setState(() => _isLoading = true);
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      Uint8List pngBytes = byteData.buffer.asUint8List();
      String base64Image = base64Encode(pngBytes);
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection("gallery").add({
        "image_data": base64Image,
        "author_id": user?.uid ?? "anonymous",
        "createdAt": FieldValue.serverTimestamp(),
      });

      await ImageGallerySaverPlus.saveImage(pngBytes, quality: 100, name: "draw_${DateTime.now().millisecond}");
      await _showSuccessNotification();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCanvas() async {
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final String filePath = '${tempDir.path}/draw_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = await File(filePath).create();
        await file.writeAsBytes(pngBytes);
        await Share.shareXFiles([XFile(filePath)], text: 'Мой рисунок');
      }
    } catch (e) { debugPrint("Share error: $e"); }
  }

  void _undo() {
    if (points.isNotEmpty) {
      setState(() {
        redoHistory.add(List.from(points));
        if (points.last == null) points.removeLast();
        while (points.isNotEmpty && points.last != null) { points.removeLast(); }
      });
    }
  }

  void _redo() {
    if (redoHistory.isNotEmpty) {
      setState(() => points = List.from(redoHistory.removeLast()));
    }
  }

  void _showSizePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF604490),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Container(height: 150, padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text("Толщина: ${strokeWidth.round()}", style: const TextStyle(color: Colors.white)),
            Slider(value: strokeWidth, min: 1, max: 50, activeColor: Colors.white,
              onChanged: (val) { setModalState(() => strokeWidth = val); setState(() => strokeWidth = val); },
            ),
          ]),
        );
      }),
    );
  }

  void _showColorPicker() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Выберите цвет'),
      content: SingleChildScrollView(child: ColorPicker(pickerColor: selectedColor, onColorChanged: (c) => setState(() => selectedColor = c))),
      actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Готово'))],
    ));
  }

  Future<void> _importImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await File(file.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() => backgroundImage = frame.image);
    }
  }
}

// Отрисовка
class MyPainter extends CustomPainter {
  final List<DrawingPoint?> pointsList;
  final ui.Image? bgImage;
  MyPainter({required this.pointsList, this.bgImage});

  @override
  void paint(Canvas canvas, Size size) {
    if (bgImage != null) {
      paintImage(canvas: canvas, rect: Rect.fromLTWH(0, 0, size.width, size.height), image: bgImage!, fit: BoxFit.contain);
    }
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        canvas.drawLine(pointsList[i]!.offset, pointsList[i + 1]!.offset, pointsList[i]!.paint);
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        canvas.drawPoints(PointMode.points, [pointsList[i]!.offset], pointsList[i]!.paint);
      }
    }
  }
  @override bool shouldRepaint(covariant MyPainter oldDelegate) => true;
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}