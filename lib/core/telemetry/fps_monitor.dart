import 'dart:ui';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fpsProvider = NotifierProvider<FpsNotifier, double>(FpsNotifier.new);

class FpsNotifier extends Notifier<double> {
  @override
  double build() {
    _startMonitoring();
    return 0.0;
  }

  void _startMonitoring() {
    SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      if (timings.isEmpty) return;

      double totalDuration = 0;
      for (final timing in timings) {
        totalDuration += timing.totalSpan.inMilliseconds;
      }
      
      final averageDuration = totalDuration / timings.length;
      final fps = averageDuration > 0 ? 1000 / averageDuration : 60.0;
      
      state = fps.clamp(0.0, 60.0);
    });
  }
}

