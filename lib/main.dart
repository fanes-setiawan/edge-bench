import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/edge_theme.dart';
import 'core/telemetry/widgets/telemetry_overlay.dart';
import 'features/bench/bench_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: EdgeBenchApp(),
    ),
  );
}

class EdgeBenchApp extends StatelessWidget {
  const EdgeBenchApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdgeBench',
      theme: EdgeTheme.darkTheme,
      home: const MainWrapper(),
    );
  }
}

class MainWrapper extends StatelessWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: const [
          BenchScreen(),
          TelemetryOverlay(),
        ],
      ),
    );
  }
}
