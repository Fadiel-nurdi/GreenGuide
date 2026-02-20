import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CircleCropScreen extends StatefulWidget {
  final File imageFile;

  const CircleCropScreen({super.key, required this.imageFile});

  @override
  State<CircleCropScreen> createState() => _CircleCropScreenState();
}

class _CircleCropScreenState extends State<CircleCropScreen> {
  final TransformationController _controller = TransformationController();

  double _rotation = 0; // radian
  late img.Image _originImage;

  @override
  void initState() {
    super.initState();
    final bytes = widget.imageFile.readAsBytesSync();
    _originImage = img.decodeImage(bytes)!;
  }

  // ================= ROTATE =================
  void _rotateLeft() {
    setState(() {
      _rotation -= pi / 2;
    });
  }

  void _rotateRight() {
    setState(() {
      _rotation += pi / 2;
    });
  }

  // ================= CONFIRM (FIX ERROR) =================
  Future<void> _onConfirmCrop() async {
    await _save();
  }

  // ================= SAVE CROP =================
  Future<void> _save() async {
    final matrix = _controller.value;

    final scale = matrix.getMaxScaleOnAxis();
    final translate = matrix.getTranslation();

    final size = min(_originImage.width, _originImage.height);

    final centerX = _originImage.width / 2;
    final centerY = _originImage.height / 2;

    final cropX = (centerX - size / 2 - translate.x / scale).clamp(
      0,
      _originImage.width - size,
    );

    final cropY = (centerY - size / 2 - translate.y / scale).clamp(
      0,
      _originImage.height - size,
    );

    img.Image cropped = img.copyCrop(
      _originImage,
      x: cropX.round(),
      y: cropY.round(),
      width: size,
      height: size,
    );

    if (_rotation != 0) {
      cropped = img.copyRotate(cropped, angle: _rotation * 180 / pi);
    }

    cropped = img.copyResize(cropped, width: 512, height: 512);

    // ===== MASK BULAT =====
    final circle = img.Image(width: 512, height: 512);
    const radius = 256;

    for (int y = 0; y < 512; y++) {
      for (int x = 0; x < 512; x++) {
        final dx = x - radius;
        final dy = y - radius;
        if (dx * dx + dy * dy <= radius * radius) {
          circle.setPixel(x, y, cropped.getPixel(x, y));
        }
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/profile_circle.png');
    await file.writeAsBytes(img.encodePng(circle));

    if (mounted) Navigator.pop(context, file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Atur Foto Profil',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _onConfirmCrop,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipOval(
                  child: InteractiveViewer(
                    transformationController: _controller,
                    minScale: 0.8,
                    maxScale: 4,
                    child: Transform.rotate(
                      angle: _rotation,
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.rotate_left, color: Colors.white),
                    onPressed: _rotateLeft,
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.rotate_right, color: Colors.white),
                    onPressed: _rotateRight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
