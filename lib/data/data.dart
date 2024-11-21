import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class ClusterIconPainter {
  final int clusterSize;

  ClusterIconPainter(this.clusterSize);

  Future<Uint8List> getClusterIconBytes() async {
    const canvasSize = Size(300, 300); // Reasonable canvas size
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Load your custom PNG image
    final ByteData imageData =
        await rootBundle.load('assets/images/custom.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final ui.Image image = await decodeImageFromList(imageBytes);

    // Scale the image (increase size by 3x)
    final double scale = 3.0;
    final double scaledWidth = image.width * scale;
    final double scaledHeight = image.height * scale;

    // Calculate position to center the scaled image
    final Offset imageOffset = Offset(
      (canvasSize.width - scaledWidth) / 2,
      (canvasSize.height - scaledHeight) / 2 + 10,
    );

    // Draw the scaled image with anti-aliasing for better quality
    final Rect imageRect = Rect.fromLTWH(
      imageOffset.dx,
      imageOffset.dy,
      scaledWidth,
      scaledHeight,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint()
        ..filterQuality =
            ui.FilterQuality.high // High quality for image rendering
        ..isAntiAlias = true,
    );

    // Set up the text painter for the cluster size
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: clusterSize.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 50, // Larger text for high-res canvas
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position the text dynamically on top of the image
    final Offset textOffset = Offset(
      (canvasSize.width - textPainter.width) / 2,
      (canvasSize.height - textPainter.height) / 2,
    );

    // Draw the text
    textPainter.paint(canvas, textOffset);

    // Generate the final image at a reasonable resolution
    final ui.Image finalImage = await recorder
        .endRecording()
        .toImage(canvasSize.width.toInt(), canvasSize.height.toInt());
    final ByteData? pngBytes =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }
}
