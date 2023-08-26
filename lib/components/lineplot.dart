import 'dart:async';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/SoundRecorder.dart';

class MyLinePlot extends StatefulWidget {
  final List<double> data;

  const MyLinePlot({
    super.key,
    required this.data,
  });

  @override
  State<StatefulWidget> createState() {
    return MyLinePlotState();
  }
}

class MyLinePlotState extends State<MyLinePlot> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: widget.data
                  .mapIndexed((index, v) => FlSpot(index.toDouble(), v))
                  .toList(),
              isCurved: false,
              dotData: const FlDotData(
                show: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
