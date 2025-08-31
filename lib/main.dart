import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() => runApp(const BrainApp());

class BrainApp extends StatelessWidget {
  const BrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Interactive Brain')),
        body: Center(child: BrainWidget()),
      ),
    );
  }
}

class BrainWidget extends StatefulWidget {
  const BrainWidget({super.key});

  @override
  State<BrainWidget> createState() => _BrainWidgetState();
}

class _BrainWidgetState extends State<BrainWidget> {
  static const int rows = 9;
  static const int cols = 10;
  final List<bool> active = List<bool>.filled(rows * cols, false);
  late Path _brainPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final length = min(constraints.maxWidth, constraints.maxHeight);
        final size = Size(length, length);
        _brainPath = _buildBrainPath(size);
        return Center(
          child: GestureDetector(
            onTapDown: (details) {
              final local = details.localPosition;
              if (!_brainPath.contains(local)) return;
              final cellWidth = size.width / cols;
              final cellHeight = size.height / rows;
              final col = (local.dx / cellWidth).floor();
              final row = (local.dy / cellHeight).floor();
              final idx = row * cols + col;
              setState(() => active[idx] = true);
            },
            child: CustomPaint(
              size: size,
              painter: BrainPainter(active: active),
            ),
          ),
        );
      },
    );
  }

  Path _buildBrainPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w / 2, 0);
    path.quadraticBezierTo(w * 0.25, 0, w * 0.25, h * 0.1);
    path.quadraticBezierTo(0, h * 0.2, 0, h * 0.5);
    path.quadraticBezierTo(0, h * 0.8, w * 0.25, h * 0.9);
    path.quadraticBezierTo(w * 0.25, h, w / 2, h);
    path.quadraticBezierTo(w * 0.75, h, w * 0.75, h * 0.9);
    path.quadraticBezierTo(w, h * 0.8, w, h * 0.5);
    path.quadraticBezierTo(w, h * 0.2, w * 0.75, h * 0.1);
    path.quadraticBezierTo(w * 0.75, 0, w / 2, 0);
    path.close();
    return path;
  }
}

class BrainPainter extends CustomPainter {
  BrainPainter({required this.active});

  final List<bool> active;
  static const int rows = 9;
  static const int cols = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final brainPath = _buildBrainPath(size);
    canvas.save();
    canvas.clipPath(brainPath);

    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final idx = row * cols + col;
        final rect = Rect.fromLTWH(
            col * cellWidth, row * cellHeight, cellWidth, cellHeight);
        final fillPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = active[idx] ? Colors.green : Colors.white;
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
      }
    }

    canvas.restore();

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black;
    canvas.drawPath(brainPath, outlinePaint);
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), outlinePaint);
  }

  Path _buildBrainPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w / 2, 0);
    path.quadraticBezierTo(w * 0.25, 0, w * 0.25, h * 0.1);
    path.quadraticBezierTo(0, h * 0.2, 0, h * 0.5);
    path.quadraticBezierTo(0, h * 0.8, w * 0.25, h * 0.9);
    path.quadraticBezierTo(w * 0.25, h, w / 2, h);
    path.quadraticBezierTo(w * 0.75, h, w * 0.75, h * 0.9);
    path.quadraticBezierTo(w, h * 0.8, w, h * 0.5);
    path.quadraticBezierTo(w, h * 0.2, w * 0.75, h * 0.1);
    path.quadraticBezierTo(w * 0.75, 0, w / 2, 0);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant BrainPainter oldDelegate) =>
      !listEquals(active, oldDelegate.active);
}
