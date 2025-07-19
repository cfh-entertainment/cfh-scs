import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class SimpleLineChart extends StatelessWidget {
  final List<SensorData> data;
  const SimpleLineChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _LineChartPainter(data),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<SensorData> data;
  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // 1) Wertebereiche ermitteln
    final times =
        data.map((e) => e.timestamp.millisecondsSinceEpoch.toDouble());
    final vals = data.map((e) {
      final first = e.dataJson.values.first;
      return first is num ? first.toDouble() : 0.0;
    });
    final minT = times.reduce(min), maxT = times.reduce(max);
    final minV = vals .reduce(min), maxV = vals .reduce(max);
    final dt = maxT - minT;
    final dv = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    // 2) Pfad bauen
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final e = data[i];
      final first = e.dataJson.values.first;
      final val = first is num ? first.toDouble() : 0.0;
      final x = (e.timestamp.millisecondsSinceEpoch - minT) / dt * size.width;
      final y = size.height - (val - minV) / dv * size.height;
      if (i == 0) path.moveTo(x, y);
      else       path.lineTo(x, y);
    }

    // 3) Achsen zeichnen
    final axisPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;
    // X-Achse
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);
    // Y-Achse
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);

    // 4) Linie zeichnen
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => true;
}
