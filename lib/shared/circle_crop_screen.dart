import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class CircleCropScreen extends StatefulWidget {
  final File imageFile;

  const CircleCropScreen({super.key, required this.imageFile});

  @override
  State<CircleCropScreen> createState() => _CircleCropScreenState();
}
final GlobalKey _previewKey = GlobalKey();
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
    try {
      // Try to capture the exact rendered preview using RepaintBoundary. This ensures the
      // saved PNG visually matches what the user sees (including pan/zoom/rotation and clipping).
      final boundaryContext = _previewKey.currentContext;
      if (boundaryContext == null) {
        debugPrint('Preview key context is null, falling back to programmatic crop');
        await _saveProgrammaticFallback();
        return;
      }

      final renderObject = boundaryContext.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        debugPrint('RenderObject is not a RenderRepaintBoundary, falling back');
        await _saveProgrammaticFallback();
        return;
      }

      final RenderRepaintBoundary boundary = renderObject as RenderRepaintBoundary;

      // Increase pixelRatio for better quality output
      final pixelRatio = 2.0;
      final ui.Image captured = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await captured.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to capture image bytes');

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      debugPrint('Captured preview bytes length=${pngBytes.length}');

      // Decode with package:image to ensure consistent PNG and to enforce size (512x512)
      img.Image? decoded = img.decodeImage(pngBytes);
      if (decoded == null) throw Exception('Failed to decode captured image');

      // Resize to 512x512 to match previous behavior
      final img.Image resized = img.copyResize(decoded, width: 512, height: 512);

      // Ensure circular mask (in case platform didn't preserve transparent corners)
      final circle = img.Image(width: 512, height: 512);
      const radius = 256;
      final center = radius;
      // Remove call to fill() which is not present in package:image; default pixels are 0.
      for (int y = 0; y < 512; y++) {
        for (int x = 0; x < 512; x++) {
          final dx = x - center;
          final dy = y - center;
          if (dx * dx + dy * dy <= radius * radius) {
            circle.setPixel(x, y, resized.getPixel(x, y));
          }
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_circle.png');
      await file.writeAsBytes(img.encodePng(circle));

      if (mounted) Navigator.pop(context, file);
    } catch (e, st) {
      debugPrint('Error while saving crop: $e\n$st');
      // fallback - try previous programmatic approach for compatibility
      await _saveProgrammaticFallback();
    }
  }

  // Fallback: original programmatic crop method kept for safety if capture fails
  Future<void> _saveProgrammaticFallback() async {
    try {
      final matrix = _controller.value;

      final scale = matrix.getMaxScaleOnAxis();
      final translation = matrix.getTranslation();

      final imageW = _originImage.width.toDouble();
      final imageH = _originImage.height.toDouble();

      final double squareSize = min(imageW, imageH);
      final double centerX = imageW / 2;
      final double centerY = imageH / 2;
      final double cropSize = squareSize / scale;

      final double cropX = (centerX - cropSize / 2 - translation.x / scale).clamp(0, imageW - cropSize);
      final double cropY = (centerY - cropSize / 2 - translation.y / scale).clamp(0, imageH - cropSize);

      img.Image cropped = img.copyCrop(
        _originImage,
        x: cropX.round(),
        y: cropY.round(),
        width: cropSize.round(),
        height: cropSize.round(),
      );

      if (_rotation != 0) {
        cropped = img.copyRotate(cropped, angle: _rotation * 180 / pi);
      }

      cropped = img.copyResize(cropped, width: 512, height: 512);

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
    } catch (e, st) {
      debugPrint('Fallback crop failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memproses crop')));
      }
    }
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
              child: RepaintBoundary(
                key: _previewKey,
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
